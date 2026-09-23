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
    let longPressAction: String?
    let longPressOutput: String
    let swipeUpAction: String?
    let swipeUpOutput: String
    let swipeDownAction: String?
    let swipeDownOutput: String
    let swipeLeftAction: String?
    let swipeLeftOutput: String
    let swipeRightAction: String?
    let swipeRightOutput: String

    private enum CodingKeys: String, CodingKey {
        case label, output, width, height, cornerRadius, fontSize, fontWeight
        case backgroundHex, foregroundHex, pressedHex, action, haptic, sound
        case longPressAction, longPressOutput
        case swipeUpAction, swipeUpOutput
        case swipeDownAction, swipeDownOutput
        case swipeLeftAction, swipeLeftOutput
        case swipeRightAction, swipeRightOutput
    }

    init(label: String, output: String, width: Double, height: Double, cornerRadius: Double,
         fontSize: Double, fontWeight: Int, backgroundHex: String, foregroundHex: String,
         pressedHex: String, action: String, haptic: Bool, sound: Bool,
         longPressAction: String? = nil, longPressOutput: String = "",
         swipeUpAction: String? = nil, swipeUpOutput: String = "",
         swipeDownAction: String? = nil, swipeDownOutput: String = "",
         swipeLeftAction: String? = nil, swipeLeftOutput: String = "",
         swipeRightAction: String? = nil, swipeRightOutput: String = "") {
        self.label = label; self.output = output; self.width = width; self.height = height
        self.cornerRadius = cornerRadius; self.fontSize = fontSize; self.fontWeight = fontWeight
        self.backgroundHex = backgroundHex; self.foregroundHex = foregroundHex; self.pressedHex = pressedHex
        self.action = action; self.haptic = haptic; self.sound = sound
        self.longPressAction = longPressAction; self.longPressOutput = longPressOutput
        self.swipeUpAction = swipeUpAction; self.swipeUpOutput = swipeUpOutput
        self.swipeDownAction = swipeDownAction; self.swipeDownOutput = swipeDownOutput
        self.swipeLeftAction = swipeLeftAction; self.swipeLeftOutput = swipeLeftOutput
        self.swipeRightAction = swipeRightAction; self.swipeRightOutput = swipeRightOutput
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = try c.decode(String.self, forKey: .label)
        output = try c.decode(String.self, forKey: .output)
        width = try c.decodeIfPresent(Double.self, forKey: .width) ?? 1
        height = try c.decodeIfPresent(Double.self, forKey: .height) ?? 1
        cornerRadius = try c.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 9
        fontSize = try c.decodeIfPresent(Double.self, forKey: .fontSize) ?? 16
        fontWeight = try c.decodeIfPresent(Int.self, forKey: .fontWeight) ?? 600
        backgroundHex = try c.decodeIfPresent(String.self, forKey: .backgroundHex) ?? "#171724"
        foregroundHex = try c.decodeIfPresent(String.self, forKey: .foregroundHex) ?? "#FFFFFF"
        pressedHex = try c.decodeIfPresent(String.self, forKey: .pressedHex) ?? "#635BFF"
        action = try c.decodeIfPresent(String.self, forKey: .action) ?? "text"
        haptic = try c.decodeIfPresent(Bool.self, forKey: .haptic) ?? true
        sound = try c.decodeIfPresent(Bool.self, forKey: .sound) ?? false
        longPressAction = try c.decodeIfPresent(String.self, forKey: .longPressAction)
        longPressOutput = try c.decodeIfPresent(String.self, forKey: .longPressOutput) ?? ""
        swipeUpAction = try c.decodeIfPresent(String.self, forKey: .swipeUpAction)
        swipeUpOutput = try c.decodeIfPresent(String.self, forKey: .swipeUpOutput) ?? ""
        swipeDownAction = try c.decodeIfPresent(String.self, forKey: .swipeDownAction)
        swipeDownOutput = try c.decodeIfPresent(String.self, forKey: .swipeDownOutput) ?? ""
        swipeLeftAction = try c.decodeIfPresent(String.self, forKey: .swipeLeftAction)
        swipeLeftOutput = try c.decodeIfPresent(String.self, forKey: .swipeLeftOutput) ?? ""
        swipeRightAction = try c.decodeIfPresent(String.self, forKey: .swipeRightAction)
        swipeRightOutput = try c.decodeIfPresent(String.self, forKey: .swipeRightOutput) ?? ""
    }
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
