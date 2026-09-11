import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage(AppTheme.colorStorageKey) private var themeIndex = 0
    @State private var path: [Route] = []
    @State private var showSettings = false

    enum Route: Hashable {
        case manager
        case game(String)
    }

    var body: some View {
        ZStack {
            TnCheatsBackground()
            NavigationStack(path: $path) {
                HomeOfficialView(
                    onManager: { path.append(.manager) },
                    onSettings: { showSettings = true }
                )
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .manager:
                        PatchManagerView(onGame: { path.append(.game($0)) })
                    case .game(let gameID):
                        GamePatchView(gameID: gameID)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .background(Color.clear)
            }
        }
        .id(themeIndex)
        .background(Color.clear)
        .tint(AppTheme.accent)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .environment(\.layoutDirection, .leftToRight)
    }
}

private struct HomeOfficialView: View {
    let onManager: () -> Void
    let onSettings: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                header
                noticeCard
                supportCard
                actionCard(title: "Trình Quản Lý Patch", subtitle: "Free Fire TH / Free Fire Max", icon: "shippingbox.fill", action: onManager)
                actionCard(title: "Cài Đặt", subtitle: "Màu Liquid Glass / Tắt tất cả patch", icon: "gearshape.fill", action: onSettings)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .background(Color.clear)
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppLogo(size: 58)
            VStack(alignment: .leading, spacing: 2) {
                Text("TnCheats")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.white, AppTheme.silver], startPoint: .top, endPoint: .bottom))
                Text("CONTROL PANEL")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(3.2)
                    .foregroundStyle(AppTheme.silver.opacity(0.58))
            }
            Spacer()
            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.accent.opacity(0.10), in: Circle())
                    .overlay(Circle().stroke(AppTheme.accent.opacity(0.38), lineWidth: 0.8))
                    .shadow(color: AppTheme.accent.opacity(0.22), radius: 8)
            }
            .buttonStyle(.plain)
        }
    }

    private var noticeCard: some View {
        homeCard("Thông báo", "Quy tắc bật patch", "bell.fill") {
            VStack(alignment: .leading, spacing: 9) {
                noticeRow("Aim bật khi đứng sảnh.")
                noticeRow("Mod bật trước khi vô game (1 lần).")
                noticeRow("Holo, định vị khi load 40% out ra bật (1 lần).")
            }
        }
    }

    private var supportCard: some View {
        homeCard("Thiết bị được hỗ trợ", "Kiểm tra môi trường thiết bị", "iphone.gen3") {
            HStack(spacing: 8) {
                Circle().fill(AppTheme.accent).frame(width: 7, height: 7)
                Text("Thiết bị tương thích")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    private func noticeRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.silver.opacity(0.78))
        }
    }

    @ViewBuilder
    private func homeCard<Content: View>(_ title: String, _ subtitle: String, _ icon: String, @ViewBuilder content: () -> Content) -> some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 12) {
                    iconTile(icon)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title).font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                        Text(subtitle).font(.system(size: 11, weight: .medium)).foregroundStyle(AppTheme.silver.opacity(0.48))
                    }
                    Spacer()
                }
                content()
            }
        }
    }

    private func actionCard(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            GlassCard(cornerRadius: 24) {
                HStack(spacing: 13) {
                    iconTile(icon)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                        Text(subtitle).font(.system(size: 11, weight: .medium)).foregroundStyle(AppTheme.silver.opacity(0.48))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.accent.opacity(0.72))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func iconTile(_ icon: String) -> some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(AppTheme.accent.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(AppTheme.accent.opacity(0.30), lineWidth: 0.8))
            .overlay(Image(systemName: icon).foregroundStyle(AppTheme.accent).font(.system(size: 18, weight: .semibold)))
            .shadow(color: AppTheme.accent.opacity(0.12), radius: 7)
            .frame(width: 48, height: 48)
    }
}

private struct PatchManagerView: View {
    let onGame: (String) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                title("Trình Quản Lý Patch", subtitle: "Chọn game để quản lý patch")
                gameCard(id: "ffth", name: "Free Fire TH", bundle: BundledPatchStore.ffthBundleID, icon: "flame.fill")
                gameCard(id: "ffmax", name: "Free Fire Max", bundle: BundledPatchStore.ffmaxBundleID, icon: "flame.circle.fill")
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .background(Color.clear)
    }

    private func gameCard(id: String, name: String, bundle: String, icon: String) -> some View {
        Button { onGame(id) } label: {
            GlassCard(cornerRadius: 25) {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.accent.opacity(0.13))
                        .overlay(Image(systemName: icon).font(.system(size: 23, weight: .bold)).foregroundStyle(AppTheme.accent))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.accent.opacity(0.28), lineWidth: 0.8))
                        .frame(width: 58, height: 58)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(name).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.white)
                        Text(bundle).font(.system(size: 10, design: .monospaced)).foregroundStyle(AppTheme.silver.opacity(0.45))
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(AppTheme.accent.opacity(0.72))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func title(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 28, weight: .black, design: .rounded)).foregroundStyle(.white)
            Text(subtitle).font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.silver.opacity(0.50))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
}

private struct GamePatchView: View {
    let gameID: String
    @State private var patches: [BundledPatch] = []
    @State private var states: [String: Bool] = [:]
    @State private var busy = false
    @State private var errorMessage: String?
    @State private var masterState: [BundledPatch.PatchCategory: Bool] = [:]

    private var gameName: String { gameID == "ffth" ? "Free Fire TH" : "Free Fire Max" }
    private var bundleID: String { gameID == "ffth" ? BundledPatchStore.ffthBundleID : BundledPatchStore.ffmaxBundleID }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                header
                ForEach(BundledPatch.PatchCategory.allCases) { category in
                    categoryCard(category)
                }
                openGameButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear(perform: load)
        .background(Color.clear)
        .alert("TnCheats", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(gameName).font(.system(size: 28, weight: .black, design: .rounded)).foregroundStyle(.white)
            Text("AIM • ĐỊNH VỊ • MOD")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundStyle(AppTheme.accent.opacity(0.80))
            Text("Tắt patch sẽ tự động khôi phục file gốc.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.silver.opacity(0.50))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 3)
    }

    private func categoryCard(_ category: BundledPatch.PatchCategory) -> some View {
        let items = patches.filter { $0.category == category }
        let on = masterState[category] ?? false
        return GlassCard(cornerRadius: 23) {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue).font(.system(size: 14, weight: .black)).tracking(1.5).foregroundStyle(AppTheme.accent)
                        Text(category == .aim ? "Chỉ 1 aim được bật" : "\(items.count) patch")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.silver.opacity(0.42))
                    }
                    Spacer()
                    LiquidGlassToggle(isOn: Binding(get: { on }, set: { toggleMaster(category, enabled: $0, items: items) }))
                }
                .padding(.bottom, 10)

                ForEach(items) { patch in
                    patchRow(patch)
                    if patch.id != items.last?.id { Divider().overlay(AppTheme.silver.opacity(0.08)).padding(.vertical, 1) }
                }
            }
        }
    }

    private func patchRow(_ patch: BundledPatch) -> some View {
        let enabled = states[patch.id] ?? false
        return HStack(spacing: 11) {
            Image(systemName: icon(for: patch.category))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(enabled ? AppTheme.accent : AppTheme.silver.opacity(0.58))
                .frame(width: 34, height: 34)
                .background(AppTheme.accent.opacity(enabled ? 0.10 : 0.035), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(AppTheme.accent.opacity(enabled ? 0.28 : 0.10), lineWidth: 0.6))
            VStack(alignment: .leading, spacing: 3) {
                Text(patch.displayName).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                Text("Patch tích hợp")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(patch.passwordProtected ? AppTheme.silver.opacity(0.46) : AppTheme.accent.opacity(0.75))
            }
            Spacer()
            LiquidGlassToggle(isOn: Binding(get: { enabled }, set: { togglePatch(patch, enabled: $0) }))
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }

    private var openGameButton: some View {
        Button { openGame() } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("MỞ APP")
            }
            .font(.system(size: 14, weight: .black))
            .tracking(1.2)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AppTheme.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.accent.opacity(0.42), lineWidth: 0.9))
            .shadow(color: AppTheme.accent.opacity(0.18), radius: 10)
        }
        .buttonStyle(.plain)
        .disabled(busy)
        .opacity(busy ? 0.55 : 1)
    }

    private func load() {
        patches = BundledPatchStore.patches(for: gameID)
        for patch in patches {
            states[patch.id] = DevicePatchService.latestReceipt(projectID: patch.packageID) != nil
        }
        for category in BundledPatch.PatchCategory.allCases {
            let items = patches.filter { $0.category == category }
            masterState[category] = category == .aim
                ? items.contains(where: { states[$0.id] == true })
                : (!items.isEmpty && items.allSatisfy { states[$0.id] == true })
        }
    }

    private func togglePatch(_ patch: BundledPatch, enabled: Bool) {
        guard !busy else { return }
        if enabled {
            if patch.category == .aim {
                let others = patches.filter { $0.category == .aim && $0.id != patch.id && states[$0.id] == true }
                if !others.isEmpty { restoreMany(others, thenApply: patch) } else { requestApply(patch) }
            } else {
                requestApply(patch)
            }
        } else {
            restore(patch)
        }
    }

    private func requestApply(_ patch: BundledPatch) {
        applyMany([patch])
    }

    private func toggleMaster(_ category: BundledPatch.PatchCategory, enabled: Bool, items: [BundledPatch]) {
        guard !busy else { return }
        if category == .aim {
            if enabled {
                guard let selected = items.first(where: { states[$0.id] != true }) ?? items.first else { return }
                let others = items.filter { $0.id != selected.id && states[$0.id] == true }
                if !others.isEmpty { restoreMany(others, thenApply: selected) } else { requestApply(selected) }
            } else {
                restoreMany(items.filter { states[$0.id] == true })
            }
            return
        }

        if enabled {
            let needed = items.filter { !(states[$0.id] ?? false) }
            guard !needed.isEmpty else { return }
            applyMany(needed)
        } else {
            restoreMany(items.filter { states[$0.id] == true })
        }
    }

    private func applyMany(_ items: [BundledPatch]) {
        guard !items.isEmpty else { return }
        busy = true
        let group = DispatchGroup()
        var firstError: Error?
        let lock = NSLock()

        for patch in items {
            if states[patch.id] == true { continue }
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let project = try BundledPatchStore.decode(patch)
                    guard project.allBundleIdentifiers.contains(bundleID) else { throw PatchPackageError.invalidBundleIdentifier }
                    _ = try DevicePatchService.apply(project: project)
                } catch {
                    lock.lock(); if firstError == nil { firstError = error }; lock.unlock()
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            busy = false
            if let error = firstError { errorMessage = error.localizedDescription }
            load()
        }
    }

    private func restore(_ patch: BundledPatch) {
        restoreMany([patch])
    }

    private func restoreMany(_ items: [BundledPatch], thenApply next: BundledPatch? = nil) {
        let active = items.filter { DevicePatchService.latestReceipt(projectID: $0.packageID) != nil }
        if active.isEmpty {
            if let next { requestApply(next) } else { load() }
            return
        }
        busy = true
        let group = DispatchGroup()
        var firstError: Error?
        let lock = NSLock()
        for patch in active {
            guard let receipt = DevicePatchService.latestReceipt(projectID: patch.packageID) else { continue }
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                do { try DevicePatchService.restore(receipt: receipt) }
                catch { lock.lock(); if firstError == nil { firstError = error }; lock.unlock() }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            busy = false
            if let error = firstError {
                errorMessage = error.localizedDescription
                load()
            } else if let next {
                requestApply(next)
            } else {
                load()
            }
        }
    }

    private func openGame() {
        let scheme = gameID == "ffth" ? "freefireth" : "freefiremax"
        guard let url = URL(string: "\(scheme)://") else { return }
        UIApplication.shared.open(url)
    }

    private func icon(for category: BundledPatch.PatchCategory) -> String {
        switch category {
        case .aim: return "scope"
        case .locate: return "location.fill"
        case .mod: return "sparkles"
        }
    }

}

private struct PatchPasswordCard: View {
    let title: String
    @Binding var password: String
    let onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Patch được bảo vệ") {
                    SecureField("Mật khẩu", text: $password)
                    Button("Tiếp tục") { onContinue() }.disabled(password.isEmpty)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: Content
    init(cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) { self.cornerRadius = cornerRadius; self.content = content() }
    var body: some View { LiquidGlassSurface(cornerRadius: cornerRadius) { content.padding(17).frame(maxWidth: .infinity) } }
}
