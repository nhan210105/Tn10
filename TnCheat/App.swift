import SwiftUI
import UIKit

@main
@MainActor
struct TnCheatApp: SwiftUI.App {
    @SwiftUI.StateObject private var appState = AppState()
    @SwiftUI.StateObject private var patchDraftCoordinator = PatchDraftCoordinator()
    @SwiftUI.StateObject private var fileOperationCoordinator = FileOperationCoordinator()
    @SwiftUI.StateObject private var patchStore = PatchProjectStore()
    @SwiftUI.StateObject private var repositoryStore = PackageRepositoryStore()
    @SwiftUI.AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @SwiftUI.State private var updateOffer: AppUpdateChecker.Offer?
    @SwiftUI.Environment(\.scenePhase) private var scenePhase

    init() {
        setupLogCapture()
        log("app: TnCheats launching — iOS \(AppInfo.osVersion) (\(AppInfo.osBuild)) \(AppInfo.machineName)")
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(patchDraftCoordinator)
                .environmentObject(fileOperationCoordinator)
                .environmentObject(patchStore)
                .environmentObject(repositoryStore)
                .environment(\.appLanguage, language)
                .environment(\.locale, language.locale)
                .alert(item: $updateOffer) { offer in
                    Alert(
                        title: Text(language.text("update.title")),
                        message: Text(language.text("update.message", offer.version)),
                        primaryButton: .default(Text(language.text("update.agree"))) {
                            UIApplication.shared.open(offer.url)
                        },
                        secondaryButton: .cancel(Text(language.text("update.dismiss"))) {
                            AppUpdateChecker.dismiss(version: offer.version)
                        }
                    )
                }
                .onAppear {
                    appState.detectSupport()
                }
                .task {
                    if let offer = await AppUpdateChecker.check() {
                        updateOffer = offer
                    }
                }
                .onChange(of: scenePhase) { phase in
                    guard phase == .active else { return }
                    appState.detectSupport()
                }
                .onOpenURL { url in
                    patchDraftCoordinator.presentImport(url)
                }
        }
    }
}

class AppState: ObservableObject {
    @Published var exploitStatus: ExploitStatus = .notStarted
    @Published var unsupportedMessage: String?
    @Published var kernelExploitRunning = false
    @Published var patchResetInProgress = false
    @Published var patchResetError: String?

    private let initialPatchStateKey = "TnCheats.initialPatchStateReset.v1"
    private var autoRunAttempted = false

    var kernelExploitApplicable: Bool {
        KernelExploit.isApplicable(
            major: AppInfo.versionTuple.major,
            minor: AppInfo.versionTuple.minor,
            patch: AppInfo.versionTuple.patch,
            build: AppInfo.osBuild
        )
    }

    var isSupported: Bool { unsupportedMessage == nil }

    func detectSupport() {
        resetBundledPatchesOnFreshInstallIfNeeded()
        let v = AppInfo.versionTuple
        let supported = ExploitSupportPolicy.isSupported(
            major: v.major,
            minor: v.minor,
            patch: v.patch,
            build: AppInfo.osBuild
        )
#if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--simulate-access") {
            exploitStatus = .success(method: "Simulator preview")
        }
#endif

        unsupportedMessage = supported ? nil : "iOS \(AppInfo.osVersion) (\(AppInfo.osBuild))"
        if let unsupportedMessage {
            exploitStatus = .unsupported(unsupportedMessage)
            return
        }

        let applicable = KernelExploit.isApplicable(
            major: v.major,
            minor: v.minor,
            patch: v.patch,
            build: AppInfo.osBuild
        )
        guard applicable else { return }

        refreshKernelExploitStatus()
        maybeAutoRunKernelExploit()
    }

    private func maybeAutoRunKernelExploit() {
        guard !kernelExploitRunning,
              !exploitStatus.isSuccess,
              !exploitStatus.isFailed,
              !autoRunAttempted else { return }
        autoRunAttempted = true
        log("app: starting kernel exploit automatically")
        runKernelExploitIfNeeded()
    }

    private func refreshKernelExploitStatus() {
        guard !kernelExploitRunning else { return }

        // iOS < 26: kernel R/W success persists (no sandbox probe)
        // iOS >= 26: verify full sandbox escape is still active
        if KernelExploit.requiresSandboxEscape {
            if KernelExploit.hasSandboxAccess() {
                if !exploitStatus.isSuccess {
                    exploitStatus = .success(method: "kexploit")
                    log("app: existing sandbox access is still active; skipping kernel exploit")
                }
            } else if exploitStatus.isSuccess {
                exploitStatus = .notStarted
                log("app: sandbox access is no longer active")
            }
        }
    }


    func restoreAllBundledPatches() {
        guard !patchResetInProgress else { return }
        patchResetInProgress = true
        patchResetError = nil
        let patches = BundledPatchStore.all()
        DispatchQueue.global(qos: .userInitiated).async {
            var firstError: Error?
            for patch in patches {
                guard let receipt = DevicePatchService.latestReceipt(projectID: patch.packageID) else { continue }
                do {
                    try DevicePatchService.restore(receipt: receipt)
                } catch {
                    if firstError == nil { firstError = error }
                }
            }
            DispatchQueue.main.async {
                self.patchResetInProgress = false
                self.patchResetError = firstError?.localizedDescription
            }
        }
    }

    private func resetBundledPatchesOnFreshInstallIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: initialPatchStateKey) else { return }
        UserDefaults.standard.set(true, forKey: initialPatchStateKey)
        restoreAllBundledPatches()
    }

    func runKernelExploitIfNeeded() {
        refreshKernelExploitStatus()
        guard !kernelExploitRunning,
              !exploitStatus.isSuccess,
              !exploitStatus.isFailed else { return }
        kernelExploitRunning = true
        exploitStatus = .notStarted
        log("app: running kernel exploit on background...")
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = KernelExploit.run()
            DispatchQueue.main.async {
                self.kernelExploitRunning = false
                if ok {
                    self.exploitStatus = .success(method: "kexploit")
                    if KernelExploit.requiresSandboxEscape {
                        log("app: kernel exploit success — sandbox access verified")
                    } else {
                        log("app: kernel exploit success — kernel access active")
                    }
                } else {
                    self.exploitStatus = .failed(method: "kexploit", code: -1)
                    log("app: kernel exploit failed — relaunch the app before retrying")
                }
            }
        }
    }
}
