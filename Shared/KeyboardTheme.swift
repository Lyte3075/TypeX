import Foundation

struct KeyboardTheme: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var backgroundHex: String
    var keyHex: String
    var accentHex: String
    var textHex: String

    static let typeX = KeyboardTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "TypeX",
        backgroundHex: "#0B0B12",
        keyHex: "#171724",
        accentHex: "#635BFF",
        textHex: "#FFFFFF"
    )
}
