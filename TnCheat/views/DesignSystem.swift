import SwiftUI

// TnCheats visual system. Patch application/restore continues to use the 3105 engine.
enum AppTheme {
    static let colorStorageKey = "TnCheats.selectedLiquidGlassColor"

    struct PaletteItem: Identifiable, Hashable {
        let id: Int
        let name: String
        let color: Color
        let secondary: Color
    }

    static let palette: [PaletteItem] = [
        .init(id: 0, name: "Aqua", color: Color(red: 0.00, green: 0.72, blue: 1.00), secondary: Color(red: 0.00, green: 0.36, blue: 0.86)),
        .init(id: 1, name: "Violet", color: Color(red: 0.46, green: 0.34, blue: 1.00), secondary: Color(red: 0.22, green: 0.12, blue: 0.74)),
        .init(id: 2, name: "Purple", color: Color(red: 0.72, green: 0.32, blue: 1.00), secondary: Color(red: 0.44, green: 0.10, blue: 0.78)),
        .init(id: 3, name: "Pink", color: Color(red: 1.00, green: 0.24, blue: 0.68), secondary: Color(red: 0.80, green: 0.06, blue: 0.38)),
        .init(id: 4, name: "Red", color: Color(red: 1.00, green: 0.18, blue: 0.22), secondary: Color(red: 0.72, green: 0.02, blue: 0.05)),
        .init(id: 5, name: "Orange", color: Color(red: 1.00, green: 0.42, blue: 0.08), secondary: Color(red: 0.84, green: 0.15, blue: 0.01)),
        .init(id: 6, name: "Gold", color: Color(red: 1.00, green: 0.76, blue: 0.08), secondary: Color(red: 0.72, green: 0.42, blue: 0.01)),
        .init(id: 7, name: "Green", color: Color(red: 0.16, green: 0.94, blue: 0.52), secondary: Color(red: 0.02, green: 0.58, blue: 0.24)),
        .init(id: 8, name: "Mint", color: Color(red: 0.12, green: 1.00, blue: 0.88), secondary: Color(red: 0.02, green: 0.60, blue: 0.52)),
        .init(id: 9, name: "Blue", color: Color(red: 0.20, green: 0.48, blue: 1.00), secondary: Color(red: 0.04, green: 0.18, blue: 0.76))
    ]

    static var selectedIndex: Int {
        let raw = UserDefaults.standard.integer(forKey: colorStorageKey)
        return palette.indices.contains(raw) ? raw : 0
    }

    static var accent: Color { palette[selectedIndex].color }
    static var accentSoft: Color { palette[selectedIndex].secondary }
    static let silver = Color(red: 0.86, green: 0.88, blue: 0.92)
    static let pageBackground = Color.black.opacity(0.18)
    static let consoleBackground = Color.black.opacity(0.28)
    static let navBarBackground = Color.clear
    static let glassFill = Color.white.opacity(0.055)
    static let glassHighlight = Color.white.opacity(0.10)
    static let pageInset: CGFloat = 16
    static let rowIconSize: CGFloat = 17
    static let rowIconFrame: CGFloat = 28
    static let fileRowIconSize: CGFloat = 17
    static let fileRowIconFrame: CGFloat = 30
    static let fileRowHeight: CGFloat = 60
    static let appIconSize: CGFloat = 32
    static let emptyIconSize: CGFloat = 30
    static let selectionIconSize: CGFloat = 18
    static let contentCardCornerRadius: CGFloat = 20
    static let contentCardInset: CGFloat = 16
    static let contentCardPadding: CGFloat = 16
    static let glassBlurOpacity: Double = 0.72
    static let glassStrokeOpacity: Double = 0.24
}

struct LiquidGlassSurface<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: Content
    init(cornerRadius: CGFloat = AppTheme.contentCardCornerRadius, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }

    var body: some View {
        content
            .background {
                shape.fill(
                    LinearGradient(
                        colors: [
                            AppTheme.accent.opacity(0.095),
                            Color.white.opacity(0.045),
                            AppTheme.consoleBackground.opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .overlay {
                shape.stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.34),
                            AppTheme.accent.opacity(0.34),
                            AppTheme.accentSoft.opacity(0.20),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 0.8
                )
                .allowsHitTesting(false)
            }
            .overlay {
                shape.stroke(AppTheme.accent.opacity(0.10), lineWidth: 0.5).allowsHitTesting(false)
            }
    }
}

struct LiquidGlassToggle: View {
    @Binding var isOn: Bool
    @State private var pulse = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                isOn.toggle()
                pulse.toggle()
            }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.accent.opacity(isOn ? 0.46 : 0.08),
                                Color.white.opacity(isOn ? 0.13 : 0.055),
                                AppTheme.accentSoft.opacity(isOn ? 0.30 : 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(Capsule().stroke(AppTheme.accent.opacity(isOn ? 0.72 : 0.18), lineWidth: 0.9))
                    .shadow(color: AppTheme.accent.opacity(isOn ? 0.40 : 0.04), radius: isOn ? 9 : 2)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.96), AppTheme.accent.opacity(isOn ? 0.88 : 0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.65), lineWidth: 0.6))
                    .frame(width: 25, height: 25)
                    .shadow(color: AppTheme.accent.opacity(isOn ? 0.75 : 0.12), radius: isOn ? 7 : 2)
                    .scaleEffect(pulse ? 1.08 : 1.0)
                    .padding(3)
            }
            .frame(width: 56, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Tắt" : "Bật")
    }
}

struct GlassToggle: View {
    @Binding var isOn: Bool
    var body: some View { LiquidGlassToggle(isOn: $isOn) }
}

struct TnCheatsBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                let w = max(proxy.size.width, 1)
                let h = max(proxy.size.height, 1)
                ZStack {
                    // Deep base so the animation remains visible without washing out text.
                    LinearGradient(
                        colors: [
                            AppTheme.accentSoft.opacity(0.55),
                            Color.black.opacity(0.18),
                            AppTheme.accent.opacity(0.42)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    orb(
                        x: w * 0.18 + CGFloat(sin(t * 0.42)) * w * 0.16,
                        y: h * 0.16 + CGFloat(cos(t * 0.34)) * h * 0.12,
                        size: max(w, h) * 0.78,
                        opacity: 0.82
                    )
                    orb(
                        x: w * 0.86 + CGFloat(cos(t * 0.31)) * w * 0.18,
                        y: h * 0.43 + CGFloat(sin(t * 0.37)) * h * 0.16,
                        size: max(w, h) * 0.70,
                        opacity: 0.70
                    )
                    orb(
                        x: w * 0.48 + CGFloat(sin(t * 0.27)) * w * 0.20,
                        y: h * 0.88 + CGFloat(cos(t * 0.29)) * h * 0.12,
                        size: max(w, h) * 0.74,
                        opacity: 0.62
                    )

                    // A slow electric sweep gives the selected color a visible animated glow.
                    RoundedRectangle(cornerRadius: 0)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    AppTheme.accent.opacity(0.42),
                                    AppTheme.accentSoft.opacity(0.28),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(Double(sin(t * 0.16)) * 7))
                        .scaleEffect(1.35)
                        .blur(radius: 18)

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.02),
                            .clear,
                            Color.black.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(width: w, height: h)
                .clipped()
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func orb(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        AppTheme.accent.opacity(opacity),
                        AppTheme.accentSoft.opacity(opacity * 0.62),
                        AppTheme.accent.opacity(0.04),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.5
                )
            )
            .frame(width: size, height: size)
            .position(x: x, y: y)
            .blur(radius: 22)
    }
}
struct GlassCardBackground: View {
    var cornerRadius: CGFloat = AppTheme.contentCardCornerRadius
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(LinearGradient(colors: [AppTheme.accent.opacity(0.09), Color.white.opacity(0.045), AppTheme.consoleBackground.opacity(0.80)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(AppTheme.accent.opacity(0.28), lineWidth: 0.8))
    }
}

struct AppCardBorder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.contentCardCornerRadius, style: .continuous)
            .strokeBorder(LinearGradient(colors: [AppTheme.silver.opacity(0.28), AppTheme.accent.opacity(0.24), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.8)
            .accessibilityHidden(true)
    }
}

struct AppRowIcon: View {
    let systemName: String
    var tint: Color = AppTheme.accent
    var symbolSize: CGFloat = AppTheme.rowIconSize
    var frameSize: CGFloat = AppTheme.rowIconFrame
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(tint.opacity(0.10)).overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(tint.opacity(0.18), lineWidth: 0.6))
            Image(systemName: systemName).font(.system(size: symbolSize, weight: .medium)).foregroundStyle(tint)
        }
        .frame(width: frameSize, height: frameSize)
        .accessibilityHidden(true)
    }
}

struct AppSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearLabel: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 14, weight: .medium)).foregroundStyle(AppTheme.silver.opacity(0.70)).accessibilityHidden(true)
            TextField(prompt, text: $text).font(.body).foregroundStyle(.white).textInputAutocapitalization(.never).autocorrectionDisabled().submitLabel(.search)
            if !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 14, weight: .medium)).foregroundStyle(.tertiary) }.buttonStyle(.plain).accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 40)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.055)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.silver.opacity(0.13), lineWidth: 0.7))
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
        .background(AppTheme.navBarBackground.opacity(0.92))
    }
}

struct AppLogo: View {
    var size: CGFloat = 44
    var body: some View {
        Group {
            if let icon = UIImage(named: "AppIcon60x60")
                ?? Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
                ?? UIImage(named: "AppIcon") {
                Image(uiImage: icon).resizable().scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous).fill(AppTheme.accent)
                    Image(systemName: "bolt.fill").font(.title2.weight(.black)).foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous).stroke(AppTheme.accent.opacity(0.42), lineWidth: 0.8))
        .shadow(color: AppTheme.accent.opacity(0.30), radius: 10)
        .accessibilityHidden(true)
    }
}
