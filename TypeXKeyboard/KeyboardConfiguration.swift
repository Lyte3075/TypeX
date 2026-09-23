import Foundation

struct TypeXExtensionKey: Codable {
    let label: String
    let output: String
    let width: Double
    let height: Double
    let cornerRadius: Double
    let fontSize: Double
    let fontWeight: Int
    let backgroundHex: String
    let foregroundHex: String
    let pressedHex: String
    let action: String
    let haptic: Bool
    let sound: Bool
    let longPressOutput: String
    let swipeUpOutput: String
    let swipeDownOutput: String
    let swipeLeftOutput: String
    let swipeRightOutput: String
}

struct TypeXExtensionRow: Codable {
    let keys: [TypeXExtensionKey]
}

struct TypeXExtensionKeyboard: Codable {
    let name: String
    let rows: [TypeXExtensionRow]
    let backgroundHex: String
    let keyDefaultHex: String
    let textHex: String
    let accentHex: String
    let keyPressedHex: String
    let rowSpacing: Double
    let keySpacing: Double
    let keyHeight: Double
    let cornerRadius: Double
    let fontSize: Double
    let keyboardHeight: Double
    let opacity: Double
    let haptics: Bool
    let sounds: Bool
    let autoCapitalize: Bool
    let doubleSpacePeriod: Bool
    let smartQuotes: Bool
    let smartDashes: Bool
}

enum TypeXSharedStore {
    static let appGroupID = "group.com.typex.shared"
    static let keyboardKey = "TypeX.currentKeyboard"

    static func loadKeyboard() -> TypeXExtensionKeyboard? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: keyboardKey) else { return nil }
        return try? JSONDecoder().decode(TypeXExtensionKeyboard.self, from: data)
    }
}
