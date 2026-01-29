import UIKit

final class PianoKeyboardView: UIView {

    // MARK: - Key Models
    private struct WhiteKey {
        let note: String
    }

    private struct BlackKey {
        let note: String
        let positionAfterWhiteIndex: Int
    }

    // One octave: C D E F G A B
    private let whiteKeysModel: [WhiteKey] = [
        .init(note: "C"),
        .init(note: "D"),
        .init(note: "E"),
        .init(note: "F"),
        .init(note: "G"),
        .init(note: "A"),
        .init(note: "B")
    ]

    // Black keys: C#, D#, F#, G#, A#
    private let blackKeysModel: [BlackKey] = [
        .init(note: "C#", positionAfterWhiteIndex: 0),
        .init(note: "D#", positionAfterWhiteIndex: 1),
        .init(note: "F#", positionAfterWhiteIndex: 3),
        .init(note: "G#", positionAfterWhiteIndex: 4),
        .init(note: "A#", positionAfterWhiteIndex: 5)
    ]

    // MARK: - Output
    var onNotePressed: ((String) -> Void)?

    private var whiteKeyButtons: [UIButton] = []
    private var blackKeyButtons: [UIButton] = []

    // MARK: - Visual Feedback

    private var lastPressedButton: UIButton?

    func showCorrect(note: String) {
        highlight(note: note, color: UIColor.systemGreen)
    }

    func showIncorrect(note: String) {
        highlight(note: note, color: UIColor.systemRed)
    }

    func resetHighlights() {
        for b in whiteKeyButtons {
            b.backgroundColor = .white
        }
        for b in blackKeyButtons {
            b.backgroundColor = .black
        }
        lastPressedButton = nil
    }

    /// Flashes a key green or red, then resets it to its default color.
    func flash(note: String, correct: Bool) {
        let color: UIColor = correct ? .systemGreen : .systemRed
        highlight(note: note, color: color)

        let keyToReset = lastPressedButton

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard let button = keyToReset else { return }
            if self.blackKeyButtons.contains(button) {
                button.backgroundColor = .black
            } else {
                button.backgroundColor = .white
            }
        }
    }

    private func normalize(_ note: String) -> String {
        note
            .replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "♭", with: "b")
            .replacingOccurrences(of: "4", with: "")
            .replacingOccurrences(of: "5", with: "")
    }

    private func highlight(note: String, color: UIColor) {
        let normalized = normalize(note)

        if let index = whiteKeysModel.firstIndex(where: { normalize($0.note) == normalized }) {
            let b = whiteKeyButtons[index]
            b.backgroundColor = color
            lastPressedButton = b
            return
        }

        if let index = blackKeysModel.firstIndex(where: { normalize($0.note) == normalized }) {
            let b = blackKeyButtons[index]
            b.backgroundColor = color
            lastPressedButton = b
            return
        }
    }

    // MARK: - Key Press Animation
    private func pressAnimation(_ button: UIButton) {
        UIView.animate(withDuration: 0.08, animations: {
            button.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.08) {
                button.transform = .identity
            }
        }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupKeys()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = UIColor.systemGray6
        layer.cornerRadius = 14
        clipsToBounds = true
    }

    private func setupKeys() {
        // White keys
        for (index, keyModel) in whiteKeysModel.enumerated() {
            let button = makeWhiteKey(note: keyModel.note)
            button.tag = index
            addSubview(button)
            whiteKeyButtons.append(button)
        }

        // Black keys
        for (index, keyModel) in blackKeysModel.enumerated() {
            let button = makeBlackKey(note: keyModel.note)
            button.tag = index
            addSubview(button)
            blackKeyButtons.append(button)
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let horizontalInset: CGFloat = 12
        let verticalInset: CGFloat = 10

        let contentWidth = bounds.width - horizontalInset * 2
        let contentHeight = bounds.height - verticalInset * 2

        let whiteKeyWidth = contentWidth / CGFloat(whiteKeysModel.count)
        let whiteKeyHeight = contentHeight

        // Layout white keys
        for (i, button) in whiteKeyButtons.enumerated() {
            let x = horizontalInset + CGFloat(i) * whiteKeyWidth
            button.frame = CGRect(
                x: x,
                y: verticalInset,
                width: whiteKeyWidth,
                height: whiteKeyHeight
            )
        }

        // Layout black keys
        let blackKeyWidth = whiteKeyWidth * 0.6
        let blackKeyHeight = whiteKeyHeight * 0.6

        for (i, keyModel) in blackKeysModel.enumerated() {
            let whiteIndex = keyModel.positionAfterWhiteIndex
            let baseX = horizontalInset + CGFloat(whiteIndex + 1) * whiteKeyWidth
            let x = baseX - blackKeyWidth / 2

            let button = blackKeyButtons[i]
            button.frame = CGRect(
                x: x,
                y: verticalInset,
                width: blackKeyWidth,
                height: blackKeyHeight
            )
            bringSubviewToFront(button)
        }
    }

    // MARK: - Button Factory

    private func makeWhiteKey(note: String) -> UIButton {
        let b = UIButton(type: .system)
        b.backgroundColor = .white
        b.layer.borderWidth = 0.5
        b.layer.borderColor = UIColor.black.withAlphaComponent(0.4).cgColor
        b.layer.cornerRadius = 6
        b.setTitle(note, for: .normal)
        b.setTitleColor(.clear, for: .normal)
        b.addTarget(self, action: #selector(whiteKeyTapped(_:)), for: .touchUpInside)
        return b
    }

    private func makeBlackKey(note: String) -> UIButton {
        let b = UIButton(type: .system)
        b.backgroundColor = .black
        b.layer.cornerRadius = 6
        b.setTitle(note, for: .normal)
        b.setTitleColor(.clear, for: .normal)
        b.addTarget(self, action: #selector(blackKeyTapped(_:)), for: .touchUpInside)
        return b
    }

    // MARK: - Actions

    @objc private func whiteKeyTapped(_ sender: UIButton) {
        pressAnimation(sender)
        let note = whiteKeysModel[sender.tag].note
        onNotePressed?(note)
    }

    @objc private func blackKeyTapped(_ sender: UIButton) {
        pressAnimation(sender)
        let note = blackKeysModel[sender.tag].note
        onNotePressed?(note)
    }
}
