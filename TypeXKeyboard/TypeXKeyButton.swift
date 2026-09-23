import UIKit

final class TypeXKeyButton: UIButton {
    var output = ""
    var actionName = "text"
    var longPressAction = ""
    var longPressOutput = ""
    var swipeUpAction = ""
    var swipeUpOutput = ""
    var swipeDownAction = ""
    var swipeDownOutput = ""
    var swipeLeftAction = ""
    var swipeLeftOutput = ""
    var swipeRightAction = ""
    var swipeRightOutput = ""

    private var initialPoint = CGPoint.zero
    private var didSwipe = false
    private var longPressTriggered = false
    private var longPressTimer: Timer?

    var onActivate: ((TypeXKeyButton) -> Void)?
    var onLongPress: ((TypeXKeyButton) -> Void)?
    var onSwipe: ((TypeXKeyButton, String, String) -> Void)?

    func configure(with key: TypeXExtensionKey) {
        setTitle(key.label, for: .normal)
        output = key.output
        actionName = key.action
        longPressAction = key.longPressAction ?? ""
        longPressOutput = key.longPressOutput
        swipeUpAction = key.swipeUpAction ?? ""
        swipeUpOutput = key.swipeUpOutput
        swipeDownAction = key.swipeDownAction ?? ""
        swipeDownOutput = key.swipeDownOutput
        swipeLeftAction = key.swipeLeftAction ?? ""
        swipeLeftOutput = key.swipeLeftOutput
        swipeRightAction = key.swipeRightAction ?? ""
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
        longPressTriggered = false
        alpha = 0.65
        longPressTimer?.invalidate()
        if !longPressAction.isEmpty {
            longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
                guard let self else { return }
                self.longPressTriggered = true
                self.onLongPress?(self)
            }
        }
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let dx = point.x - initialPoint.x
        let dy = point.y - initialPoint.y
        if max(abs(dx), abs(dy)) > 28 {
            longPressTimer?.invalidate()
            if !didSwipe {
                didSwipe = true
                let action: String
                let value: String
                if abs(dx) > abs(dy) {
                    action = dx > 0 ? swipeRightAction : swipeLeftAction
                    value = dx > 0 ? swipeRightOutput : swipeLeftOutput
                } else {
                    action = dy > 0 ? swipeDownAction : swipeUpAction
                    value = dy > 0 ? swipeDownOutput : swipeUpOutput
                }
                if !action.isEmpty || !value.isEmpty {
                    onSwipe?(self, action, value)
                }
            }
        }
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        longPressTimer?.invalidate()
        alpha = 1
        if !didSwipe && !longPressTriggered { onActivate?(self) }
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        longPressTimer?.invalidate()
        alpha = 1
        super.touchesCancelled(touches, with: event)
    }

    deinit {
        longPressTimer?.invalidate()
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
