import Foundation

enum PatchApplyStage: String {
    case resolve = "RESOLVE"
    case exists = "EXISTS"
    case writable = "WRITABLE"
    case write = "WRITE"
    case verify = "VERIFY"
    case rollback = "ROLLBACK"
}

struct PatchApplyDiagnosticError: LocalizedError {
    let stage: PatchApplyStage
    let bundleID: String
    let path: String
    let detail: String

    var errorDescription: String? {
        var message = "Patch lỗi tại bước \(stage.rawValue)\nApp: \(bundleID)\nPath: \(path)"
        if !detail.isEmpty { message += "\nChi tiết: \(detail)" }
        return message
    }
}


enum DevicePatchService {
    static func apply(project: PatchProject) throws -> PatchTransactionReceipt {
        let bundleIDs = orderedBundleIdentifiers(in: project)
        return try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try preflight(project: project, roots: roots)
            return try PatchTransaction.apply(
                project: project,
                backupRoot: try PatchProjectLibrary.backupRootURL(),
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                },
                beforeWrite: { index in
                    guard index < project.rules.count else { return }
                    let rule = project.rules[index]
                    log("patch: WRITE begin bundle=\(rule.bundleID) path=\(rule.relativePath)")
                }
            )
        }
    }

    static func inspectRestore(receipt: PatchTransactionReceipt) throws -> PatchRestoreInspection {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        return try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.inspectRestore(
                receipt: receipt,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func restore(
        receipt: PatchTransactionReceipt,
        allowChangedTargets: Bool = false
    ) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.restore(
                receipt: receipt,
                allowChangedTargets: allowChangedTargets,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func resetToAppliedState(
        receipt: PatchTransactionReceipt,
        project: PatchProject
    ) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.resetToAppliedState(
                receipt: receipt,
                fallbackProject: project,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func latestReceipt(projectID: UUID) -> PatchTransactionReceipt? {
        guard let backupRoot = try? PatchProjectLibrary.backupRootURL() else { return nil }
        return PatchTransaction.latestReceipt(projectID: projectID, backupRoot: backupRoot)
    }

    private static func orderedBundleIdentifiers(in project: PatchProject) -> [String] {
        project.allBundleIdentifiers
    }

    private static func withResolvedContainers<T>(
        bundleIDs: [String],
        operation: ([String: URL]) throws -> T
    ) throws -> T {
        var roots: [String: URL] = [:]

        for bundleID in bundleIDs {
            log("patch: RESOLVE begin bundle=\(bundleID)")
            guard let path = ContainerStore.resolveAppContainerPath(bundleID: bundleID) else {
                throw PatchApplyDiagnosticError(stage: .resolve, bundleID: bundleID, path: "<container>", detail: "ContainerStore không resolve được application container.")
            }
            guard ContainerStore.isApplicationContainerPath(path) else {
                throw PatchApplyDiagnosticError(stage: .resolve, bundleID: bundleID, path: path, detail: "Path resolve được nhưng không phải application container hợp lệ.")
            }
            let root = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: path, isDirectory: true))

            // MCM may return the correct UUID while the process still has no
            // write extension for that container on iOS 26.x. Mirror 3105's
            // scoped-access fallback: consume the extension and retain its
            // handle before any preflight/write occurs.
            if KernelExploit.requiresSandboxEscape && !KernelExploit.hasSandboxAccess() {
                let grant = ContainerStore.grantContainerAccess(root.path)
                guard grant >= 0 else {
                    throw PatchApplyDiagnosticError(
                        stage: .writable,
                        bundleID: bundleID,
                        path: root.path,
                        detail: "Không có sandbox access; scoped container grant thất bại (handle=\(grant))."
                    )
                }
            }

            log("patch: RESOLVE ok bundle=\(bundleID) root=\(root.path)")
            roots[bundleID] = root
        }
        return try operation(roots)
    }

    private static func preflight(project: PatchProject, roots: [String: URL]) throws {
        let fm = FileManager.default
        for rule in project.rules {
            guard let root = roots[rule.bundleID] else {
                throw PatchApplyDiagnosticError(stage: .resolve, bundleID: rule.bundleID, path: rule.relativePath, detail: "Không có container root sau khi resolve.")
            }
            let target: URL
            do {
                target = try PatchPathValidator.resolveContainedTargetURL(relativePath: rule.relativePath, containerRoot: root)
            } catch {
                throw PatchApplyDiagnosticError(stage: .resolve, bundleID: rule.bundleID, path: rule.relativePath, detail: error.localizedDescription)
            }

            let exists = fm.fileExists(atPath: target.path)
            log("patch: EXISTS bundle=\(rule.bundleID) target=\(target.path) exists=\(exists)")
            if exists {
                guard fm.isReadableFile(atPath: target.path) else {
                    throw PatchApplyDiagnosticError(stage: .exists, bundleID: rule.bundleID, path: target.path, detail: "File tồn tại nhưng không đọc được để backup.")
                }
                guard fm.isWritableFile(atPath: target.path) else {
                    throw PatchApplyDiagnosticError(stage: .writable, bundleID: rule.bundleID, path: target.path, detail: "File tồn tại nhưng không writable.")
                }
            }

            let parent = target.deletingLastPathComponent()
            let parentExists = fm.fileExists(atPath: parent.path)
            log("patch: WRITABLE parent=\(parent.path) exists=\(parentExists) writable=\(fm.isWritableFile(atPath: parent.path))")
            if parentExists && !fm.isWritableFile(atPath: parent.path) {
                throw PatchApplyDiagnosticError(stage: .writable, bundleID: rule.bundleID, path: parent.path, detail: "Thư mục chứa target không writable.")
            }
            if !parentExists {
                log("patch: WRITABLE parent missing; 3105 engine sẽ tạo parent directory nếu cần")
            }
        }
    }
}
