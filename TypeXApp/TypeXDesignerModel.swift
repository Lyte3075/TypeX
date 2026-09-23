import Foundation
import SwiftUI

struct TypeXKey: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var label: String
    var output: String
    var width: Double = 1.0
    var height: Double = 1.0
    var cornerRadius: Double = 10
    var fontSize: Double = 16
    var fontWeight: Int = 600
    var backgroundHex: String = "#171724"
    var foregroundHex: String = "#FFFFFF"
    var pressedHex: String = "#635BFF"
    var action: KeyAction = .text
    var haptic: Bool = true
    var sound: Bool = true
    var longPressOutput: String = ""
    var swipeUpOutput: String = ""
    var swipeDownOutput: String = ""
    var swipeLeftOutput: String = ""
    var swipeRightOutput: String = ""
}

enum KeyAction: String, Codable, CaseIterable, Identifiable {
    case text, backspace, space, returnKey, shift, nextKeyboard, dismiss, emoji, numbers, symbols, tab, custom
    var id: String { rawValue }
    var title: String {
        switch self {
        case .text: return "Text"
        case .backspace: return "Backspace"
        case .space: return "Space"
        case .returnKey: return "Return"
        case .shift: return "Shift"
        case .nextKeyboard: return "Next Keyboard"
        case .dismiss: return "Dismiss"
        case .emoji: return "Emoji"
        case .numbers: return "Numbers"
        case .symbols: return "Symbols"
        case .tab: return "Tab"
        case .custom: return "Custom"
        }
    }
}

struct TypeXRow: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var keys: [TypeXKey]
}

struct TypeXKeyboard: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String = "My Keyboard"
    var rows: [TypeXRow] = TypeXKeyboard.defaultRows
    var backgroundHex = "#0B0B12"
    var keyDefaultHex = "#171724"
    var textHex = "#FFFFFF"
    var accentHex = "#635BFF"
    var keyPressedHex = "#3D36A8"
    var rowSpacing = 6.0
    var keySpacing = 5.0
    var keyHeight = 42.0
    var cornerRadius = 9.0
    var fontSize = 16.0
    var keyboardHeight = 260.0
    var opacity = 1.0
    var haptics = true
    var sounds = false
    var autoCapitalize = true
    var doubleSpacePeriod = true
    var smartQuotes = true
    var smartDashes = true

    static var defaultRows: [TypeXRow] {
        [
            TypeXRow(keys: ["Q","W","E","R","T","Y","U","I","O","P"].map { TypeXKey(label: $0, output: $0.lowercased()) }),
            TypeXRow(keys: ["A","S","D","F","G","H","J","K","L"].map { TypeXKey(label: $0, output: $0.lowercased()) }),
            TypeXRow(keys: ["Z","X","C","V","B","N","M"].map { TypeXKey(label: $0, output: $0.lowercased()) }),
            TypeXRow(keys: [
                TypeXKey(label: "⌫", output: "", width: 1.25, action: .backspace),
                TypeXKey(label: "space", output: " ", width: 4.5, action: .space),
                TypeXKey(label: "↵", output: "\n", width: 1.35, action: .returnKey)
            ])
        ]
    }
}

@MainActor
final class TypeXDesignerStore: ObservableObject {
    @Published var keyboard: TypeXKeyboard { didSet { save() } }
    @Published var selectedKeyID: UUID?
    private let storageKey = "TypeX.currentKeyboard"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(TypeXKeyboard.self, from: data) {
            keyboard = saved
        } else {
            keyboard = TypeXKeyboard()
        }
    }

    var selectedKey: TypeXKey? {
        guard let id = selectedKeyID else { return nil }
        return keyboard.rows.flatMap(\.keys).first { $0.id == id }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(keyboard) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func reset() {
        keyboard = TypeXKeyboard()
        selectedKeyID = nil
    }

    func addRow() {
        keyboard.rows.append(TypeXRow(keys: [TypeXKey(label: "NEW", output: "new")]))
    }

    func deleteRow(_ id: UUID) {
        keyboard.rows.removeAll { $0.id == id }
        if keyboard.rows.isEmpty { addRow() }
        selectedKeyID = nil
    }

    func addKey(to rowID: UUID) {
        guard let i = keyboard.rows.firstIndex(where: { $0.id == rowID }) else { return }
        keyboard.rows[i].keys.append(TypeXKey(label: "NEW", output: "new"))
    }

    func deleteKey(_ id: UUID) {
        for i in keyboard.rows.indices {
            keyboard.rows[i].keys.removeAll { $0.id == id }
        }
        selectedKeyID = nil
    }

    func duplicateKey(_ id: UUID) {
        for i in keyboard.rows.indices {
            guard let j = keyboard.rows[i].keys.firstIndex(where: { $0.id == id }) else { continue }
            var copy = keyboard.rows[i].keys[j]
            copy.id = UUID()
            copy.label += " Copy"
            keyboard.rows[i].keys.insert(copy, at: j + 1)
            selectedKeyID = copy.id
            return
        }
    }

    func updateSelectedKey(_ update: (inout TypeXKey) -> Void) {
        guard let id = selectedKeyID else { return }
        for i in keyboard.rows.indices {
            if let j = keyboard.rows[i].keys.firstIndex(where: { $0.id == id }) {
                update(&keyboard.rows[i].keys[j])
                return
            }
        }
    }

    func exportJSON() -> String? {
        guard let data = try? JSONEncoder().encode(keyboard) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func importJSON(_ json: String) {
        guard let data = json.data(using: .utf8),
              let imported = try? JSONDecoder().decode(TypeXKeyboard.self, from: data) else { return }
        keyboard = imported
        selectedKeyID = nil
    }
}
