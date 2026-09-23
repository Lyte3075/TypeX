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
        case .updates: UpdatesPanel()
        }
    }
}

enum DesignerSection: String, CaseIterable, Identifiable {
    case design, layout, keys, behavior, themes, updates
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}


struct UpdatesPanel: View {
    @StateObject private var versionManager = TypeXVersionManager()

    var body: some View {
        VStack(spacing: 12) {
            GroupBox("TypeX Updates") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Installed", systemImage: "checkmark.circle")
                        Spacer()
                        Text("v\(versionManager.currentVersion)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    if let latest = versionManager.latestRelease {
                        HStack(alignment: .top) {
                            Label("Latest", systemImage: versionManager.hasUpdate ? "arrow.down.circle.fill" : "checkmark.seal.fill")
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(latest.displayVersion).font(.headline)
                                Text(latest.name).font(.caption).foregroundStyle(.secondary)
                            }
                        }

                        if versionManager.hasUpdate {
                            Button {
                                versionManager.open(latest)
                            } label: {
                                Label("Get Latest Update", systemImage: "arrow.down.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Text("You're running the newest release available on GitHub.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Check GitHub for the newest TypeX release.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task { await versionManager.refresh() }
                    } label: {
                        Label(versionManager.isLoading ? "Checking..." : "Check for Updates",
                              systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(versionManager.isLoading)
                }
            }

            GroupBox("Version History") {
                if versionManager.releases.isEmpty {
                    Text("No releases loaded yet. Tap Check for Updates.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 8) {
                        ForEach(versionManager.releases) { release in
                            Button {
                                versionManager.open(release)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(release.name).foregroundStyle(.primary)
                                        Text(release.displayVersion)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if release.displayVersion == versionManager.currentVersion {
                                        Text("Installed")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    } else if release.prerelease {
                                        Text("Pre-release")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if let error = versionManager.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Text("iOS note: TypeX can check releases and open the selected GitHub release. Installing an iOS build still depends on Apple's supported distribution/signing method.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task {
            await versionManager.refresh()
        }
    }
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

            GroupBox("Rows & Keys") {
                VStack(spacing: 10) {
                    ForEach(store.keyboard.rows) { row in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Row • (row.keys.count) keys")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Button { store.moveRow(row.id, offset: -1) } label: {
                                    Image(systemName: "arrow.up")
                                }
                                .disabled(store.keyboard.rows.first?.id == row.id)

                                Button { store.moveRow(row.id, offset: 1) } label: {
                                    Image(systemName: "arrow.down")
                                }
                                .disabled(store.keyboard.rows.last?.id == row.id)

                                Button("Add Key") { store.addKey(to: row.id) }

                                Button(role: .destructive) {
                                    store.deleteRow(row.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .disabled(store.keyboard.rows.count <= 1)
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(row.keys) { key in
                                        HStack(spacing: 2) {
                                            Button(key.label) {
                                                store.selectedKeyID = key.id
                                            }
                                            .buttonStyle(.bordered)

                                            Button {
                                                store.moveKey(key.id, offset: -1)
                                            } label: {
                                                Image(systemName: "chevron.left")
                                            }

                                            Button {
                                                store.moveKey(key.id, offset: 1)
                                            } label: {
                                                Image(systemName: "chevron.right")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button { store.addRow() } label: {
                        Label("Add Row", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

struct KeyPanel: View {
    @ObservedObject var store: TypeXDesignerStore

    private var selectedKeyIndex: (row: Int, key: Int)? {
        guard let id = store.selectedKeyID else { return nil }
        for rowIndex in store.keyboard.rows.indices {
            if let keyIndex = store.keyboard.rows[rowIndex].keys.firstIndex(where: { $0.id == id }) {
                return (rowIndex, keyIndex)
            }
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 12) {
            GroupBox("Keys") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(store.keyboard.rows.flatMap(\\.keys)) { key in
                            Button(key.label) {
                                store.selectedKeyID = key.id
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            if let location = selectedKeyIndex {
                KeyEditor(store: store, rowIndex: location.row, keyIndex: location.key)
            } else {
                ContentUnavailableView(
                    "No key selected",
                    systemImage: "keyboard",
                    description: Text("Tap a key in the preview to edit it.")
                )
            }
        }
    }
}

struct KeyEditor: View {
    @ObservedObject var store: TypeXDesignerStore
    let rowIndex: Int
    let keyIndex: Int

    private var key: TypeXKey {
        store.keyboard.rows[rowIndex].keys[keyIndex]
    }

    private func binding<T>(_ keyPath: WritableKeyPath<TypeXKey, T>) -> Binding<T> {
        Binding(
            get: {
                guard store.keyboard.rows.indices.contains(rowIndex),
                      store.keyboard.rows[rowIndex].keys.indices.contains(keyIndex) else {
                    return key[keyPath: keyPath]
                }
                return store.keyboard.rows[rowIndex].keys[keyIndex][keyPath: keyPath]
            },
            set: { value in
                guard store.keyboard.rows.indices.contains(rowIndex),
                      store.keyboard.rows[rowIndex].keys.indices.contains(keyIndex) else { return }
                store.keyboard.rows[rowIndex].keys[keyIndex][keyPath: keyPath] = value
            }
        )
    }

    var body: some View {
        GroupBox("Key: (key.label)") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Label", text: binding(\\.label))
                    .textFieldStyle(.roundedBorder)

                TextField("Output", text: binding(\\.output))
                    .textFieldStyle(.roundedBorder)

                ActionEditor(title: "Tap action", action: binding(\\.action), output: binding(\\.output))

                Divider()
                Text("Long Press").font(.headline)
                AlternateActionEditor(action: binding(\\.longPressAction), output: binding(\\.longPressOutput))

                Divider()
                Text("Swipe Actions").font(.headline)
                SwipeActionEditor(direction: "↑", action: binding(\\.swipeUpAction), output: binding(\\.swipeUpOutput))
                SwipeActionEditor(direction: "↓", action: binding(\\.swipeDownAction), output: binding(\\.swipeDownOutput))
                SwipeActionEditor(direction: "←", action: binding(\\.swipeLeftAction), output: binding(\\.swipeLeftOutput))
                SwipeActionEditor(direction: "→", action: binding(\\.swipeRightAction), output: binding(\\.swipeRightOutput))

                Divider()
                SliderRow(title: "Width", value: binding(\\.width), range: 0.4...8)
                SliderRow(title: "Height", value: binding(\\.height), range: 0.5...3)
                SliderRow(title: "Corner radius", value: binding(\\.cornerRadius), range: 0...35)
                SliderRow(title: "Font size", value: binding(\\.fontSize), range: 8...40)
                ColorRow(title: "Background", hex: binding(\\.backgroundHex))
                ColorRow(title: "Text", hex: binding(\\.foregroundHex))
                ColorRow(title: "Pressed", hex: binding(\\.pressedHex))
                Toggle("Haptic feedback", isOn: binding(\\.haptic))
                Toggle("Key sound", isOn: binding(\\.sound))

                HStack {
                    Button("Move Left") { store.moveKey(key.id, offset: -1) }
                        .buttonStyle(.bordered)
                    Button("Move Right") { store.moveKey(key.id, offset: 1) }
                        .buttonStyle(.bordered)
                }

                HStack {
                    Button("Move to Row Above") { store.moveKey(key.id, toRow: -1) }
                        .buttonStyle(.bordered)
                        .disabled(rowIndex == 0)
                    Button("Move to Row Below") { store.moveKey(key.id, toRow: 1) }
                        .buttonStyle(.bordered)
                        .disabled(rowIndex == store.keyboard.rows.count - 1)
                }

                HStack {
                    Button("Duplicate") { store.duplicateKey(key.id) }
                        .buttonStyle(.bordered)
                    Button("Delete", role: .destructive) { store.deleteKey(key.id) }
                        .buttonStyle(.bordered)
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
