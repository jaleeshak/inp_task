import Foundation

/// Stores which Innovoprism server the app talks to.
final class AppSettings: ObservableObject {
    private static let serverKey = "serverURL"
    private static let lastServerKey = "lastServerURL"

    @Published var serverURL: URL? {
        didSet { UserDefaults.standard.set(serverURL?.absoluteString, forKey: Self.serverKey) }
    }

    /// The previous address, used to pre-fill the setup screen after "Change server".
    var lastServerURL: URL? {
        UserDefaults.standard.string(forKey: Self.lastServerKey).flatMap(URL.init(string:))
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: Self.serverKey),
           let url = URL(string: saved) {
            serverURL = url
        } else if let preset = Bundle.main.object(forInfoDictionaryKey: "DefaultServerURL") as? String,
                  let url = AppSettings.normalize(preset) {
            // Set DefaultServerURL in Info.plist so teammates skip the setup screen.
            serverURL = url
        }
    }

    func clearServer() {
        UserDefaults.standard.set(serverURL?.absoluteString, forKey: Self.lastServerKey)
        serverURL = nil
    }

    /// Turns what a person types ("100.64.0.5:8080", "innovo.tailnet.ts.net")
    /// into a full URL. Tailscale *.ts.net names get https (they come with
    /// real certificates); everything else defaults to http.
    static func normalize(_ input: String) -> URL? {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        let lower = text.lowercased()
        if !lower.hasPrefix("http://") && !lower.hasPrefix("https://") {
            let hostPart = lower.split(separator: "/").first.map(String.init) ?? lower
            let hostOnly = hostPart.split(separator: ":").first.map(String.init) ?? hostPart
            text = (hostOnly.hasSuffix(".ts.net") ? "https://" : "http://") + text
        }
        guard let url = URL(string: text), let host = url.host, !host.isEmpty else { return nil }
        return url
    }
}
