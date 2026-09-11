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
        .init(filename: "Aim Darg FFth.3105", name: "Aim Drag FFTH", category: .aim, gameID: "ffth"),
        .init(filename: "Aim Magic FFth.3105", name: "Aim Magic FFTH", category: .aim, gameID: "ffth"),
        .init(filename: "Aim Neck FFth.3105", name: "Aim Neck FFTH", category: .aim, gameID: "ffth"),
        .init(filename: "Aim Chest FFth.3105", name: "Aim Chest FFTH", category: .aim, gameID: "ffth"),
        .init(filename: "Aim body FFFth.3105", name: "Aim Body FFTH", category: .aim, gameID: "ffth"),
        .init(filename: "Định vị Đồ-Súng xanh.3105", name: "Định vị Đồ-Súng xanh", category: .locate, gameID: "ffth"),
        .init(filename: "ESP Súng Vàng Kim FFTh.3105", name: "ESP Súng Vàng Kim FFTH", category: .locate, gameID: "ffth"),
        .init(filename: "Người Nhện Ff Thg.3105", name: "Người Nhện FFTH", category: .mod, gameID: "ffth"),
        .init(filename: "Quái Nhân Đen Mod Ff Thg.3105", name: "Quái Nhân Đen Mod FFTH", category: .mod, gameID: "ffth"),
        .init(filename: "Chams Súng-Keo.3105", name: "Chams Súng-Keo", category: .mod, gameID: "ffth"),

        .init(filename: "Aim Darg.3105", name: "Aim Drag FFMAX", category: .aim, gameID: "ffmax"),
        .init(filename: "Aim Magic.3105", name: "Aim Magic FFMAX", category: .aim, gameID: "ffmax"),
        .init(filename: "Aim Neck.3105", name: "Aim Neck FFMAX", category: .aim, gameID: "ffmax"),
        .init(filename: "Aim Chest FFMAX.3105", name: "Aim Chest FFMAX", category: .aim, gameID: "ffmax"),
        .init(filename: "Aim body.3105", name: "Aim Body FFMAX", category: .aim, gameID: "ffmax"),
        .init(filename: "Định vị súng đỏ.3105", name: "Định vị súng đỏ", category: .locate, gameID: "ffmax"),
        .init(filename: "ESP Súng đen viền đỏ.3105", name: "ESP Súng đen viền đỏ", category: .locate, gameID: "ffmax"),
        .init(filename: "mod ffm.3105", name: "Mod FFM", category: .mod, gameID: "ffmax"),
        .init(filename: "SKIN FFM .3105", name: "Skin FFM", category: .mod, gameID: "ffmax"),
        .init(filename: "mod áo trắng chú rể.3105", name: "Mod áo trắng chú rể", category: .mod, gameID: "ffmax"),
        .init(filename: "mod đồ ngủ.3105", name: "Mod đồ ngủ", category: .mod, gameID: "ffmax"),
        .init(filename: "Magic.3105", name: "Magic FFMAX", category: .mod, gameID: "ffmax")
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
            let contentKey: Data
            do {
                contentKey = try PatchKeyStore.load(for: summary)
            } catch {
                throw error
            }
            return try PatchPackageCodec.decode(patch.data, contentKey: contentKey).project
        }
        return try PatchPackageCodec.decode(patch.data, password: nil).project
    }
}
