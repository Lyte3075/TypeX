import UIKit

final class TypeXKeyButton: UIButton {
    var output = ""
    var actionName = "text"
    var longPressOutput = ""
    var swipeUpOutput = ""
    var swipeDownOutput = ""
    var swipeLeftOutput = ""
    var swipeRightOutput = ""

    private var initialPoint = CGPoint.zero
    private var didSwipe = false

    var onActivate: ((TypeXKeyButton) -> Void)?
    var onSwipe: ((TypeXKeyButton, String) -> Void)?

    func configure(with key: TypeXExtensionKey) {
        setTitle(key.label, for: .normal)
        output = key.output
        actionName = key.action
        longPressOutput = key.longPressOutput
        swipeUpOutput = key.swipeUpOutput
        swipeDownOutput = key.swipeDownOutput
        swipeLeftOutput = key.swipeLeftOutput
        swipeRightOutput = key.swipeRightOutput
        titleLabel?.font = .systemFont(ofSize: key.fontSize, weight: key.fontWeight >= 700 ? .bold : .semibold)
        setTitleColor(UIColor(hex: key.foregroundHex), for: .normal)
        backgroundColor = UIColor(hex: key.backgroundHex)
        layer.cornerRadius = key.cornerRadius
        clipsToBounds = true
        accessibilityLabel = key.label
        accessibilityTraits = .keyboardKey
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        initialPoint = touches.first?.location(in: self) ?? .zero
        didSwipe = false
        alpha = 0.65
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let dx = point.x - initialPoint.x
        let dy = point.y - initialPoint.y
        if max(abs(dx), abs(dy)) > 28 {
            didSwipe = true
            let result = abs(dx) > abs(dy) ? (dx > 0 ? swipeRightOutput : swipeLeftOutput) : (dy > 0 ? swipeDownOutput : swipeUpOutput)
            if !result.isEmpty { onSwipe?(self, result) }
        }
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        alpha = 1
        if !didSwipe { onActivate?(self) }
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        alpha = 1
        super.touchesCancelled(touches, with: event)
    }
}

extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(red: CGFloat((value >> 16) & 255) / 255, green: CGFloat((value >> 8) & 255) / 255, blue: CGFloat(value & 255) / 255, alpha: 1)
    }
}
