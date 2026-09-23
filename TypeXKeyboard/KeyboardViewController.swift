import UIKit

final class KeyboardViewController: UIInputViewController {
    private let rootStack = UIStackView()
    private var configuration: TypeXExtensionKeyboard?
    private var isShifted = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        reloadKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadKeyboard()
    }

    private func reloadKeyboard() {
        configuration = TypeXSharedStore.loadKeyboard() ?? fallbackKeyboard()
        buildKeyboard()
    }

    private func buildKeyboard() {
        rootStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rootStack.removeFromSuperview()

        guard let configuration else { return }
        rootStack.axis = .vertical
        rootStack.spacing = CGFloat(configuration.rowSpacing)
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
            view.heightAnchor.constraint(equalToConstant: CGFloat(configuration.keyboardHeight))
        ])

        for row in configuration.rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = CGFloat(configuration.keySpacing)
            rowStack.distribution = .fill
            rootStack.addArrangedSubview(rowStack)

            let total = max(totalRowWidth(row), 0.1)
            for key in row.keys {
                let button = TypeXKeyButton()
                button.configure(with: key)
                button.onActivate = { [weak self] in self?.activate($0) }
                button.onSwipe = { [weak self] _, output in self?.textDocumentProxy.insertText(output) }
                rowStack.addArrangedSubview(button)

                let ratio = CGFloat(max(0.4, key.width) / total)
                button.widthAnchor.constraint(equalTo: rowStack.widthAnchor, multiplier: ratio).isActive = true
            }
            rowStack.heightAnchor.constraint(equalToConstant: CGFloat(configuration.keyHeight)).isActive = true
        }
    }

    private func totalRowWidth(_ row: TypeXExtensionRow) -> Double {
        row.keys.reduce(0) { $0 + max(0.4, $1.width) }
    }

    private func activate(_ button: TypeXKeyButton) {
        switch button.actionName {
        case "text", "custom", "numbers", "symbols":
            insert(button.output, uppercase: isShifted)
        case "backspace":
            textDocumentProxy.deleteBackward()
        case "space":
            handleSpace()
        case "returnKey":
            textDocumentProxy.insertText("\n")
        case "shift":
            isShifted.toggle()
            updateShiftTitles()
        case "nextKeyboard":
            advanceToNextInputMode()
        case "dismiss":
            dismissKeyboard()
        case "tab":
            textDocumentProxy.insertText("\t")
        case "emoji":
            textDocumentProxy.insertText("🙂")
        default:
            insert(button.output, uppercase: isShifted)
        }
    }

    private func insert(_ value: String, uppercase: Bool) {
        guard !value.isEmpty else { return }
        textDocumentProxy.insertText(uppercase ? value.uppercased() : value)
        if uppercase {
            isShifted = false
            updateShiftTitles()
        }
    }

    private func handleSpace() {
        if configuration?.doubleSpacePeriod == true,
           textDocumentProxy.documentContextBeforeInput?.last == " " {
            textDocumentProxy.deleteBackward()
            textDocumentProxy.insertText(". ")
        } else {
            textDocumentProxy.insertText(" ")
        }
    }

    private func updateShiftTitles() {
        for row in rootStack.arrangedSubviews {
            guard let stack = row as? UIStackView else { continue }
            for item in stack.arrangedSubviews {
                guard let button = item as? TypeXKeyButton,
                      button.actionName == "text",
                      let title = button.title(for: .normal) else { continue }
                button.setTitle(isShifted ? title.uppercased() : title.lowercased(), for: .normal)
            }
        }
    }

    private func fallbackKeyboard() -> TypeXExtensionKeyboard {
        let rows = [
            ["q","w","e","r","t","y","u","i","o","p"],
            ["a","s","d","f","g","h","j","k","l"],
            ["z","x","c","v","b","n","m"]
        ]

        func key(_ s: String) -> TypeXExtensionKey {
            TypeXExtensionKey(
                label: s.uppercased(), output: s, width: 1, height: 1,
                cornerRadius: 9, fontSize: 16, fontWeight: 600,
                backgroundHex: "#171724", foregroundHex: "#FFFFFF",
                pressedHex: "#635BFF", action: "text", haptic: true, sound: false,
                longPressOutput: "", swipeUpOutput: "", swipeDownOutput: "",
                swipeLeftOutput: "", swipeRightOutput: ""
            )
        }

        let bottom = [
            TypeXExtensionKey(label: "⌫", output: "", width: 1.4, height: 1, cornerRadius: 9, fontSize: 16, fontWeight: 600, backgroundHex: "#171724", foregroundHex: "#FFFFFF", pressedHex: "#635BFF", action: "backspace", haptic: true, sound: false, longPressOutput: "", swipeUpOutput: "", swipeDownOutput: "", swipeLeftOutput: "", swipeRightOutput: ""),
            TypeXExtensionKey(label: "space", output: " ", width: 4.8, height: 1, cornerRadius: 9, fontSize: 15, fontWeight: 600, backgroundHex: "#171724", foregroundHex: "#FFFFFF", pressedHex: "#635BFF", action: "space", haptic: true, sound: false, longPressOutput: "", swipeUpOutput: "", swipeDownOutput: "", swipeLeftOutput: "", swipeRightOutput: ""),
            TypeXExtensionKey(label: "↵", output: "\n", width: 1.4, height: 1, cornerRadius: 9, fontSize: 16, fontWeight: 600, backgroundHex: "#171724", foregroundHex: "#FFFFFF", pressedHex: "#635BFF", action: "returnKey", haptic: true, sound: false, longPressOutput: "", swipeUpOutput: "", swipeDownOutput: "", swipeLeftOutput: "", swipeRightOutput: "")
        ]

        return TypeXExtensionKeyboard(
            name: "TypeX",
            rows: rows.map { TypeXExtensionRow(keys: $0.map(key)) } + [TypeXExtensionRow(keys: bottom)],
            backgroundHex: "#0B0B12", keyDefaultHex: "#171724", textHex: "#FFFFFF",
            accentHex: "#635BFF", keyPressedHex: "#3D36A8", rowSpacing: 6, keySpacing: 5,
            keyHeight: 42, cornerRadius: 9, fontSize: 16, keyboardHeight: 260, opacity: 1,
            haptics: true, sounds: false, autoCapitalize: true, doubleSpacePeriod: true,
            smartQuotes: true, smartDashes: true
        )
    }
}
