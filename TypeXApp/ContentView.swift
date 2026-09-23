import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var store = TypeXDesignerStore()
    @State private var section: DesignerSection = .design
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportDocument = TypeXExportDocument()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                KeyboardCanvas(store: store)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)

                Picker("Editor", selection: $section) {
                    ForEach(DesignerSection.allCases) { s in Text(s.title).tag(s) }
                }
                .pickerStyle(.segmented)
                .padding(12)

                ScrollView {
                    editor.padding(.horizontal, 14).padding(.bottom, 30)
                }
            }
            .navigationTitle("TypeX")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Reset Keyboard", role: .destructive) { store.reset() }
                        Button("Export JSON") {
                            exportDocument = TypeXExportDocument(text: store.exportJSON() ?? "")
                            showExporter = true
                        }
                        Button("Import JSON") { showImporter = true }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text(store.keyboard.name).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                if case .success(let urls) = result, let url = urls.first,
                   let data = try? Data(contentsOf: url),
                   let json = String(data: data, encoding: .utf8) {
                    store.importJSON(json)
                }
            }
            .fileExporter(isPresented: $showExporter, document: exportDocument, contentType: .json, defaultFilename: "TypeX-Keyboard.json") { _ in }
        }
    }

    @ViewBuilder private var editor: some View {
        switch section {
        case .design: DesignPanel(store: store)
        case .layout: LayoutPanel(store: store)
        case .keys: KeyPanel(store: store)
        case .behavior: BehaviorPanel(store: store)
        case .themes: ThemePanel(store: store)
        }
    }
}

enum DesignerSection: String, CaseIterable, Identifiable {
    case design, layout, keys, behavior, themes
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct KeyboardCanvas: View {
    @ObservedObject var store: TypeXDesignerStore
    var body: some View {
        VStack(spacing: store.keyboard.rowSpacing) {
            ForEach(store.keyboard.rows) { row in
                HStack(spacing: store.keyboard.keySpacing) {
                    ForEach(row.keys) { key in
                        Button { store.selectedKeyID = key.id } label: {
                            Text(key.label)
                                .font(.system(size: key.fontSize, weight: key.fontWeight >= 700 ? .bold : .semibold))
                                .foregroundStyle(Color(hex: key.foregroundHex))
                                .frame(maxWidth: .infinity)
                                .frame(height: store.keyboard.keyHeight * key.height)
                                .background(Color(hex: key.backgroundHex))
                                .clipShape(RoundedRectangle(cornerRadius: key.cornerRadius))
                                .overlay(RoundedRectangle(cornerRadius: key.cornerRadius)
                                    .stroke(store.selectedKeyID == key.id ? Color(hex: store.keyboard.accentHex) : .clear, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(9)
        .background(Color(hex: store.keyboard.backgroundHex).opacity(store.keyboard.opacity))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.08)))
    }
}

struct DesignPanel: View {
    @ObservedObject var store: TypeXDesignerStore
    var body: some View {
        GroupBox("Keyboard Design") {
            VStack(alignment: .leading, spacing: 14) {
                TextField("Keyboard name", text: $store.keyboard.name).textFieldStyle(.roundedBorder)
                ColorRow(title: "Background", hex: $store.keyboard.backgroundHex)
                ColorRow(title: "Default keys", hex: $store.keyboard.keyDefaultHex)
                ColorRow(title: "Text", hex: $store.keyboard.textHex)
                ColorRow(title: "Accent", hex: $store.keyboard.accentHex)
                ColorRow(title: "Pressed", hex: $store.keyboard.keyPressedHex)
                SliderRow(title: "Opacity", value: $store.keyboard.opacity, range: 0.5...1)
            }
        }
    }
}

struct LayoutPanel: View {
    @ObservedObject var store: TypeXDesignerStore
    var body: some View {
        VStack(spacing: 12) {
            GroupBox("Global Layout") {
                VStack(spacing: 12) {
                    SliderRow(title: "Keyboard height", value: $store.keyboard.keyboardHeight, range: 180...380)
                    SliderRow(title: "Key height", value: $store.keyboard.keyHeight, range: 28...70)
                    SliderRow(title: "Key spacing", value: $store.keyboard.keySpacing, range: 0...14)
                    SliderRow(title: "Row spacing", value: $store.keyboard.rowSpacing, range: 0...18)
                }
            }
            GroupBox("Rows") {
                VStack(spacing: 8) {
                    ForEach(store.keyboard.rows) { row in
                        HStack {
                            Text("\(row.keys.count) keys").font(.subheadline.weight(.medium))
                            Spacer()
                            Button("Add Key") { store.addKey(to: row.id) }
                            Button(role: .destructive) { store.deleteRow(row.id) } label: { Image(systemName: "trash") }
                        }
                    }
                    Button { store.addRow() } label: { Label("Add Row", systemImage: "plus") }
                }
            }
        }
    }
}

struct KeyPanel: View {
    @ObservedObject var store: TypeXDesignerStore
    var body: some View {
        VStack(spacing: 12) {
            GroupBox("Keys") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(store.keyboard.rows.flatMap(\.keys)) { key in
                            Button(key.label) { store.selectedKeyID = key.id }.buttonStyle(.bordered)
                        }
                    }
                }
            }

            if let selected = store.selectedKey {
                GroupBox("Key: \(selected.label)") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Label", text: Binding(get: { store.selectedKey?.label ?? "" }, set: { value in store.updateSelectedKey { $0.label = value } })).textFieldStyle(.roundedBorder)
                        TextField("Output", text: Binding(get: { store.selectedKey?.output ?? "" }, set: { value in store.updateSelectedKey { $0.output = value } })).textFieldStyle(.roundedBorder)
                        ActionEditor(title: "Tap action", action: Binding(get: { store.selectedKey?.action ?? .text }, set: { value in store.updateSelectedKey { $0.action = value } }), output: Binding(get: { store.selectedKey?.output ?? "" }, set: { value in store.updateSelectedKey { $0.output = value } }))

                        Divider()
                        Text("Long Press").font(.headline)
                        AlternateActionEditor(
                            action: Binding(get: { store.selectedKey?.longPressAction }, set: { value in store.updateSelectedKey { $0.longPressAction = value } }),
                            output: Binding(get: { store.selectedKey?.longPressOutput ?? "" }, set: { value in store.updateSelectedKey { $0.longPressOutput = value } })
                        )

                        Divider()
                        Text("Swipe Actions").font(.headline)
                        SwipeActionEditor(direction: "↑", action: Binding(get: { store.selectedKey?.swipeUpAction }, set: { value in store.updateSelectedKey { $0.swipeUpAction = value } }), output: Binding(get: { store.selectedKey?.swipeUpOutput ?? "" }, set: { value in store.updateSelectedKey { $0.swipeUpOutput = value } }))
                        SwipeActionEditor(direction: "↓", action: Binding(get: { store.selectedKey?.swipeDownAction }, set: { value in store.updateSelectedKey { $0.swipeDownAction = value } }), output: Binding(get: { store.selectedKey?.swipeDownOutput ?? "" }, set: { value in store.updateSelectedKey { $0.swipeDownOutput = value } }))
                        SwipeActionEditor(direction: "←", action: Binding(get: { store.selectedKey?.swipeLeftAction }, set: { value in store.updateSelectedKey { $0.swipeLeftAction = value } }), output: Binding(get: { store.selectedKey?.swipeLeftOutput ?? "" }, set: { value in store.updateSelectedKey { $0.swipeLeftOutput = value } }))
                        SwipeActionEditor(direction: "→", action: Binding(get: { store.selectedKey?.swipeRightAction }, set: { value in store.updateSelectedKey { $0.swipeRightAction = value } }), output: Binding(get: { store.selectedKey?.swipeRightOutput ?? "" }, set: { value in store.updateSelectedKey { $0.swipeRightOutput = value } }))

                        Divider()
                        SliderRow(title: "Width", value: Binding(get: { store.selectedKey?.width ?? 1 }, set: { value in store.updateSelectedKey { $0.width = value } }), range: 0.4...8)
                        SliderRow(title: "Height", value: Binding(get: { store.selectedKey?.height ?? 1 }, set: { value in store.updateSelectedKey { $0.height = value } }), range: 0.5...3)
                        SliderRow(title: "Corner radius", value: Binding(get: { store.selectedKey?.cornerRadius ?? 10 }, set: { value in store.updateSelectedKey { $0.cornerRadius = value } }), range: 0...35)
                        SliderRow(title: "Font size", value: Binding(get: { store.selectedKey?.fontSize ?? 16 }, set: { value in store.updateSelectedKey { $0.fontSize = value } }), range: 8...40)
                        ColorRow(title: "Background", hex: Binding(get: { store.selectedKey?.backgroundHex ?? "#171724" }, set: { value in store.updateSelectedKey { $0.backgroundHex = value } }))
                        ColorRow(title: "Text", hex: Binding(get: { store.selectedKey?.foregroundHex ?? "#FFFFFF" }, set: { value in store.updateSelectedKey { $0.foregroundHex = value } }))
                        ColorRow(title: "Pressed", hex: Binding(get: { store.selectedKey?.pressedHex ?? "#635BFF" }, set: { value in store.updateSelectedKey { $0.pressedHex = value } }))
                        Toggle("Haptic feedback", isOn: Binding(get: { store.selectedKey?.haptic ?? true }, set: { value in store.updateSelectedKey { $0.haptic = value } }))
                        Toggle("Key sound", isOn: Binding(get: { store.selectedKey?.sound ?? true }, set: { value in store.updateSelectedKey { $0.sound = value } }))

                        HStack {
                            Button("Duplicate") { store.duplicateKey(selected.id) }.buttonStyle(.bordered)
                            Button("Delete", role: .destructive) { store.deleteKey(selected.id) }.buttonStyle(.bordered)
                        }
                    }
                }
            } else {
                ContentUnavailableView("No key selected", systemImage: "keyboard", description: Text("Tap a key in the preview to edit it."))
            }
        }
    }
}

struct ActionEditor: View {
    let title: String
    @Binding var action: KeyAction
    @Binding var output: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            Picker("Action", selection: $action) {
                ForEach(KeyAction.allCases) { Text($0.title).tag($0) }
            }
            if action == .text || action == .custom || action == .numbers || action == .symbols {
                TextField("Text to insert", text: $output).textFieldStyle(.roundedBorder)
            }
        }
    }
}

struct AlternateActionEditor: View {
    @Binding var action: KeyAction?
    @Binding var output: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Enabled", isOn: Binding(get: { action != nil }, set: { enabled in action = enabled ? .text : nil }))
            if let actionBinding = Binding($action) {
                Picker("Action", selection: actionBinding) {
                    ForEach(KeyAction.allCases) { Text($0.title).tag($0) }
                }
                if actionBinding.wrappedValue == .text || actionBinding.wrappedValue == .custom || actionBinding.wrappedValue == .numbers || actionBinding.wrappedValue == .symbols {
                    TextField("Text to insert", text: $output).textFieldStyle(.roundedBorder)
                }
            }
        }
    }
}

struct SwipeActionEditor: View {
    let direction: String
    @Binding var action: KeyAction?
    @Binding var output: String
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(direction).font(.title3).frame(width: 28)
            VStack(alignment: .leading, spacing: 5) {
                Toggle("Enabled", isOn: Binding(get: { action != nil }, set: { enabled in action = enabled ? .text : nil }))
                if let actionBinding = Binding($action) {
                    Picker("Action", selection: actionBinding) {
                        ForEach(KeyAction.allCases) { Text($0.title).tag($0) }
                    }
                    if actionBinding.wrappedValue == .text || actionBinding.wrappedValue == .custom || actionBinding.wrappedValue == .numbers || actionBinding.wrappedValue == .symbols {
                        TextField("Text to insert", text: $output).textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
    }
}

struct BehaviorPanel: View {
    @ObservedObject var store: TypeXDesignerStore
    var body: some View {
        GroupBox("Typing Behavior") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Haptics", isOn: $store.keyboard.haptics)
                Toggle("Key sounds", isOn: $store.keyboard.sounds)
                Toggle("Auto-capitalize", isOn: $store.keyboard.autoCapitalize)
                Toggle("Double-space period", isOn: $store.keyboard.doubleSpacePeriod)
                Toggle("Smart quotes", isOn: $store.keyboard.smartQuotes)
                Toggle("Smart dashes", isOn: $store.keyboard.smartDashes)
            }
        }
    }
}

struct ThemePanel: View {
    @ObservedObject var store: TypeXDesignerStore
    var body: some View {
        GroupBox("Built-in themes") {
            VStack(spacing: 8) {
                ThemeButton(name: "Midnight", accent: "#635BFF") { apply("#0B0B12", "#171724", "#635BFF", "#FFFFFF") }
                ThemeButton(name: "Arctic", accent: "#1683FF") { apply("#EAF1F8", "#FFFFFF", "#1683FF", "#0B0B12") }
                ThemeButton(name: "Neon", accent: "#A855F7") { apply("#05050A", "#12121C", "#A855F7", "#FFFFFF") }
            }
        }
    }
    private func apply(_ background: String, _ keys: String, _ accent: String, _ text: String) {
        store.keyboard.backgroundHex = background
        store.keyboard.keyDefaultHex = keys
        store.keyboard.accentHex = accent
        store.keyboard.textHex = text
        for i in store.keyboard.rows.indices {
            for j in store.keyboard.rows[i].keys.indices {
                store.keyboard.rows[i].keys[j].backgroundHex = keys
                store.keyboard.rows[i].keys[j].foregroundHex = text
                store.keyboard.rows[i].keys[j].pressedHex = accent
            }
        }
    }
}

struct ThemeButton: View {
    let name: String
    let accent: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Circle().fill(Color(hex: accent)).frame(width: 12, height: 12)
                Text(name)
                Spacer()
                Text("Preview").font(.caption).foregroundStyle(.secondary)
            }
        }.buttonStyle(.plain)
    }
}

struct ColorRow: View {
    let title: String
    @Binding var hex: String
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Color(hex: hex).frame(width: 28, height: 28).clipShape(RoundedRectangle(cornerRadius: 7))
            TextField("#RRGGBB", text: $hex).textFieldStyle(.roundedBorder).frame(width: 105)
        }
    }
}

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.1f", value)).foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: $value, in: range)
        }
    }
}

struct TypeXExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var text: String
    init(text: String = "") { self.text = text }
    init(configuration: ReadConfiguration) throws {
        text = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? ""
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
    }
}

#Preview { ContentView() }
