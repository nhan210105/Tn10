import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState

    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @AppStorage(FeatureVisibility.cleanerStorageKey) private var cleanerEnabled = true
    @AppStorage(FeatureVisibility.developerModeStorageKey) private var developerModeEnabled = false
    @AppStorage(AppTheme.colorStorageKey) private var themeIndex = 0

    @State private var showDeveloperKey = false
    @State private var developerKey = ""
    @State private var developerKeyError = false
    @State private var showResetConfirmation = false
    @State private var resetMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                appSection
                paletteSection
                patchSection
                languageSection
                featureSection
                deviceSection
                supportSection
            }
            .tint(AppTheme.accent)
            .navigationTitle(language.text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .confirmationDialog(
                "Tắt tất cả patch?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Khôi phục file gốc", role: .destructive) {
                    appState.restoreAllBundledPatches()
                }
                Button("Hủy", role: .cancel) { }
            } message: {
                Text("Tất cả patch TnCheats đang bật sẽ được khôi phục về file gốc.")
            }
            .alert(
                "TnCheats",
                isPresented: Binding(
                    get: { resetMessage != nil },
                    set: { if !$0 { resetMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { resetMessage = nil }
            } message: {
                Text(resetMessage ?? "")
            }
            .onChange(of: appState.patchResetError) { value in
                resetMessage = value
            }
            .sheet(isPresented: $showDeveloperKey) {
                developerSheet
            }
        }
    }

    private var appSection: some View {
        Section {
            HStack(spacing: 14) {
                AppLogo()
                VStack(alignment: .leading, spacing: 3) {
                    Text("TnCheats").font(.headline)
                    Text(language.text("common.version", appVersion))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var paletteSection: some View {
        Section("Liquid Glass") {
            LiquidGlassPaletteGrid(selectedIndex: $themeIndex)
                .padding(.vertical, 4)
            Text("Màu đã chọn áp dụng cho nền animation, kính lỏng và toàn bộ nút bật/tắt.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var patchSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("Tắt tất cả patch", systemImage: "arrow.counterclockwise.circle.fill")
            }
            .disabled(appState.patchResetInProgress)

            if appState.patchResetInProgress {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Đang khôi phục file gốc…")
                }
            }
        } footer: {
            Text("Tắt một patch sẽ khôi phục file gốc từ receipt của 3105. Nút này khôi phục tất cả patch đang hoạt động.")
        }
    }

    private var languageSection: some View {
        Section(language.text("settings.language")) {
            Picker(language.text("settings.language"), selection: $languageCode) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.displayName).tag(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var featureSection: some View {
        Section {
            Toggle(isOn: $cleanerEnabled) {
                Label(language.text("tab.cleaner"), systemImage: "sparkles")
            }

            Button {
                if developerModeEnabled {
                    developerModeEnabled = false
                } else {
                    developerKey = ""
                    developerKeyError = false
                    showDeveloperKey = true
                }
            } label: {
                HStack {
                    Label(language.text("settings.developer_mode"), systemImage: "hammer.fill")
                    Spacer()
                    Image(systemName: developerModeEnabled ? "checkmark.circle.fill" : "lock.fill")
                        .foregroundStyle(developerModeEnabled ? AppTheme.accent : .secondary)
                }
            }
            .foregroundStyle(.primary)
        } header: {
            Text(language.text("dashboard.features"))
        } footer: {
            Text(language.text("settings.developer_mode_footer"))
        }
    }

    private var deviceSection: some View {
        Section(language.text("common.device")) {
            LabeledContent(language.text("dashboard.hardware_model"), value: AppInfo.displayMachineName)
            LabeledContent(language.text("settings.ios_version"), value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
        }
    }

    private var supportSection: some View {
        Section {
            HStack {
                Text(language.text("settings.current_version"))
                Spacer()
                Text(language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"))
                    .foregroundStyle(appState.isSupported ? Color.green : Color.red)
            }
            LabeledContent("iOS 17", value: ExploitSupportPolicy.verifiedIOS17Range)
            LabeledContent("iOS 18", value: ExploitSupportPolicy.verifiedIOS18Range)
            LabeledContent("iOS 26", value: ExploitSupportPolicy.verifiedIOS26Range)
            VStack(alignment: .leading, spacing: 8) {
                Text("iOS 27.0").font(.body)
                ForEach(ExploitSupportPolicy.verifiedIOS27Builds, id: \.build) { version in
                    Text(versionLabel(version))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text(language.text("settings.verified_versions"))
        } footer: {
            Text(language.text("settings.supported_versions_footer"))
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(language.text("common.done")) { dismiss() }
                .fontWeight(.semibold)
        }
    }

    private var developerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Developer Key", text: $developerKey)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(enableDeveloperMode)
                    if developerKeyError {
                        Label("Key không hợp lệ", systemImage: "xmark.octagon.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("Chế độ nhà phát triển mặc định luôn tắt. Chỉ key hợp lệ mới mở được quyền tạo, import, sửa và xoá project/patch.")
                }
            }
            .navigationTitle("Developer Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { showDeveloperKey = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Mở") { enableDeveloperMode() }
                        .disabled(developerKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private struct LiquidGlassPaletteGrid: View {
        @Binding var selectedIndex: Int

        var body: some View {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 10)], spacing: 10) {
                ForEach(AppTheme.palette) { item in
                    PaletteColorButton(item: item, isSelected: selectedIndex == item.id) {
                        withAnimation(.easeInOut(duration: 0.20)) {
                            selectedIndex = item.id
                        }
                    }
                }
            }
        }
    }

    private struct PaletteColorButton: View {
        let item: AppTheme.PaletteItem
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: 5) {
                    Circle()
                        .fill(LinearGradient(colors: [item.color, item.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 34, height: 34)
                        .overlay {
                            Circle().stroke(Color.white.opacity(isSelected ? 0.9 : 0.18), lineWidth: isSelected ? 2 : 0.7)
                        }
                        .shadow(color: item.color.opacity(isSelected ? 0.65 : 0.15), radius: isSelected ? 7 : 2)
                    Text(item.name)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
    }

    private func enableDeveloperMode() {
        if DeveloperAccessController.verify(developerKey) {
            developerModeEnabled = true
            developerKeyError = false
            showDeveloperKey = false
        } else {
            developerModeEnabled = false
            developerKeyError = true
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0"
    }

    private func versionLabel(_ version: (beta: Int, publicBeta: Int?, build: String)) -> String {
        if let publicBeta = version.publicBeta {
            return language.text("settings.developer_public_beta_build", Int64(version.beta), Int64(publicBeta), version.build)
        }
        return language.text("settings.developer_beta_build", Int64(version.beta), version.build)
    }
}
