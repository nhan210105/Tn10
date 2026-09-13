import Foundation

struct BundledPatch: Identifiable, Hashable {
    let id: String
    let filename: String
    let displayName: String
    let category: PatchCategory
    let gameID: String
    let packageID: UUID
    let passwordProtected: Bool
    let data: Data

    enum PatchCategory: String, CaseIterable, Identifiable {
        case aim = "AIM"
        case locate = "ĐỊNH VỊ"
        case mod = "MOD"
        var id: String { rawValue }
    }
}

enum BundledPatchStore {
    static let ffthBundleID = "com.dts.freefireth"
    static let ffmaxBundleID = "com.dts.freefiremax"

    private struct ManifestItem {
        let filename: String
        let name: String
        let category: BundledPatch.PatchCategory
        let gameID: String
    }

    private static let manifest: [ManifestItem] = [
        .init(filename: "Aim Drag FFTH.3105", name: "Aim Drag FFTH", category: .aim, gameID: "ffth"),
        .init(filename: "Aim Magic FFTH.3105", name: "Aim Magic FFTH", category: .aim, gameID: "ffth"),
        .init(filename: "Aim Neck FFTH.3105", name: "Aim Neck FFTH", category: .aim, gameID: "ffth"),
        .init(filename: "Aim Chest FFTH.3105", name: "Aim Chest FFTH", category: .aim, gameID: "ffth"),
        .init(filename: "Aim Body FFTH.3105", name: "Aim Body FFTH", category: .aim, gameID: "ffth"),
        .init(filename: "Aim R8 FFTH.3105", name: "Aim R8 FFTH", category: .aim, gameID: "ffth"),
        .init(filename: "Aim Drag FFMAX.3105", name: "Aim Drag FFMAX", category: .aim, gameID: "ffmax"),
        .init(filename: "Aim Magic FFMAX.3105", name: "Aim Magic FFMAX", category: .aim, gameID: "ffmax"),
        .init(filename: "Aim Neck FFMAX.3105", name: "Aim Neck FFMAX", category: .aim, gameID: "ffmax"),
        .init(filename: "Aim Chest FFMAX.3105", name: "Aim Chest FFMAX", category: .aim, gameID: "ffmax"),
        .init(filename: "Aim Body FFMAX.3105", name: "Aim Body FFMAX", category: .aim, gameID: "ffmax"),
        .init(filename: "Aim R8 FFMAX.3105", name: "Aim R8 FFMAX", category: .aim, gameID: "ffmax")
    ]

    static func all() -> [BundledPatch] {
        manifest.compactMap { item in
            guard let url = Bundle.main.url(forResource: item.filename, withExtension: nil, subdirectory: "EmbeddedPatches"),
                  let data = try? Data(contentsOf: url),
                  let summary = try? PatchPackageCodec.inspect(data) else { return nil }
            return BundledPatch(
                id: summary.packageID.uuidString,
                filename: item.filename,
                displayName: item.name,
                category: item.category,
                gameID: item.gameID,
                packageID: summary.packageID,
                passwordProtected: summary.isPasswordProtected,
                data: data
            )
        }
    }

    static func patches(for gameID: String) -> [BundledPatch] {
        all().filter { $0.gameID == gameID }
    }

    static func decode(_ patch: BundledPatch) throws -> PatchProject {
        if patch.passwordProtected {
            let summary = try PatchPackageCodec.inspect(patch.data)
            guard let contentKey = try? PatchKeyStore.load(for: summary) else {
                throw PatchPackageError.keychainFailed
            }
            return try PatchPackageCodec.decode(patch.data, contentKey: contentKey).project
        }
        return try PatchPackageCodec.decode(patch.data, password: nil).project
    }
}
