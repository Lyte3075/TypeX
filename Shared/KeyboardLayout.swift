import Foundation

struct KeyboardLayout: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var rows: [[String]]

    static let qwerty = KeyboardLayout(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "QWERTY",
        rows: [
            ["Q","W","E","R","T","Y","U","I","O","P"],
            ["A","S","D","F","G","H","J","K","L"],
            ["Z","X","C","V","B","N","M"]
        ]
    )
}
