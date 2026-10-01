import UIKit

/// Shown instead of a blank page when the server can't be reached.
final class ConnectionErrorView: UIView {
    let retryButton = UIButton(configuration: .filled())
    let changeServerButton = UIButton(configuration: .plain())
    let serverLabel = UILabel()
    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(message: String) {
        messageLabel.text = message
        isHidden = false
    }

    private func setUp() {
        backgroundColor = .systemBackground

        let icon = UIImageView(image: UIImage(systemName: "wifi.exclamationmark"))
        icon.tintColor = .secondaryLabel
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 44, weight: .regular)

        let titleLabel = UILabel()
        titleLabel.text = "Can't reach Innovoprism"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        serverLabel.font = .preferredFont(forTextStyle: .footnote)
        serverLabel.textColor = .tertiaryLabel
        serverLabel.textAlignment = .center
        serverLabel.numberOfLines = 0

        retryButton.configuration?.title = "Try again"
        changeServerButton.configuration?.title = "Change server"

        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, messageLabel, serverLabel, retryButton, changeServerButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(24, after: serverLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -16),
        ])
    }
}
