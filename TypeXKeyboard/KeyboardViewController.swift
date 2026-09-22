import UIKit

final class KeyboardViewController: UIInputViewController {
    private let rows = KeyboardLayout.qwerty.rows

    override func viewDidLoad() {
        super.viewDidLoad()
        buildKeyboard()
    }

    private func buildKeyboard() {
        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 6
        root.distribution = .fillEqually
        root.translatesAutoresizingMaskIntoConstraints = false

        for row in rows {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 5
            stack.distribution = .fillEqually

            for character in row {
                let button = UIButton(type: .system)
                button.setTitle(character, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
                button.backgroundColor = .secondarySystemBackground
                button.layer.cornerRadius = 8
                button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
                stack.addArrangedSubview(button)
            }

            root.addArrangedSubview(stack)
        }

        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 5
        bottom.distribution = .fill

        let delete = makeButton(title: "⌫", action: #selector(deletePressed))
        let space = makeButton(title: "space", action: #selector(spacePressed))
        let returnKey = makeButton(title: "return", action: #selector(returnPressed))

        bottom.addArrangedSubview(delete)
        bottom.addArrangedSubview(space)
        bottom.addArrangedSubview(returnKey)

        root.addArrangedSubview(bottom)
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
            view.heightAnchor.constraint(equalToConstant: 260)
        ])
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func keyPressed(_ sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        textDocumentProxy.insertText(title.lowercased())
    }

    @objc private func deletePressed() {
        textDocumentProxy.deleteBackward()
    }

    @objc private func spacePressed() {
        textDocumentProxy.insertText(" ")
    }

    @objc private func returnPressed() {
        textDocumentProxy.insertText("\n")
    }
}
