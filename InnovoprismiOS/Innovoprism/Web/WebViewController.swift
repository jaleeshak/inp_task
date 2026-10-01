import UIKit
import WebKit

/// Hosts the Innovoprism web app in a full-screen WKWebView and adds what a
/// bare WKWebView leaves out: JS alert/confirm/prompt dialogs, file downloads,
/// camera/mic permission for calls, external links in Safari, pull to
/// refresh, and a friendly screen when the server can't be reached.
///
/// Two-finger long-press anywhere opens the app menu (Reload, Home,
/// Open in Safari, Change server).
final class WebViewController: UIViewController {

    private let serverURL: URL
    private let onChangeServer: () -> Void

    private var webView: WKWebView!
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let errorView = ConnectionErrorView()
    private var progressObservation: NSKeyValueObservation?
    private var downloadDestinations: [ObjectIdentifier: URL] = [:]

    init(serverURL: URL, onChangeServer: @escaping () -> Void) {
        self.serverURL = serverURL
        self.onChangeServer = onChangeServer
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpWebView()
        setUpProgressView()
        setUpErrorView()
        setUpAppMenuGesture()
        loadHome()
    }

    private func setUpWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()          // keeps you logged in between launches
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []  // alert sounds without a "tap to unlock"
        config.applicationNameForUserAgent = (config.applicationNameForUserAgent ?? "Mobile/15E148") + " InnovoprismiOS/1.0"

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = .systemBackground
        webView.isOpaque = false
        if #available(iOS 16.4, *) {
            webView.isInspectable = true   // debug from a Mac's Safari > Develop menu if ever needed
        }

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: guide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
        ])

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(handlePullToRefresh(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refresh
    }

    private func setUpProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = UIColor(named: "AccentColor")
        progressView.trackTintColor = .clear
        view.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
        ])

        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                let progress = Float(self.webView.estimatedProgress)
                self.progressView.setProgress(progress, animated: progress > self.progressView.progress)
                self.progressView.isHidden = progress >= 1
            }
        }
    }

    private func setUpErrorView() {
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.isHidden = true
        view.addSubview(errorView)
        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        errorView.serverLabel.text = serverURL.absoluteString
        errorView.retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        errorView.changeServerButton.addTarget(self, action: #selector(changeServerTapped), for: .touchUpInside)
    }

    private func setUpAppMenuGesture() {
        let press = UILongPressGestureRecognizer(target: self, action: #selector(handleAppMenuGesture(_:)))
        press.numberOfTouchesRequired = 2
        press.minimumPressDuration = 0.8
        press.delegate = self
        webView.addGestureRecognizer(press)
    }

    // MARK: - Actions

    private func loadHome() {
        errorView.isHidden = true
        webView.load(URLRequest(url: serverURL))
    }

    @objc private func handlePullToRefresh(_ sender: UIRefreshControl) {
        if webView.url == nil {
            loadHome()
        } else {
            webView.reload()
        }
    }

    @objc private func retryTapped() {
        // Retry the page you were on (keeps your place in the app), else go home.
        if let current = webView.url, let scheme = current.scheme?.lowercased(), scheme.hasPrefix("http") {
            errorView.isHidden = true
            webView.load(URLRequest(url: current))
        } else {
            loadHome()
        }
    }

    @objc private func changeServerTapped() {
        onChangeServer()
    }

    @objc private func handleAppMenuGesture(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, presentedViewController == nil else { return }

        let sheet = UIAlertController(title: "Innovoprism", message: serverURL.absoluteString, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Reload", style: .default) { [weak self] _ in
            self?.webView.reload()
        })
        sheet.addAction(UIAlertAction(title: "Go to home page", style: .default) { [weak self] _ in
            self?.loadHome()
        })
        sheet.addAction(UIAlertAction(title: "Open in Safari", style: .default) { [weak self] _ in
            guard let self else { return }
            UIApplication.shared.open(self.webView.url ?? self.serverURL)
        })
        sheet.addAction(UIAlertAction(title: "Change server…", style: .destructive) { [weak self] _ in
            self?.onChangeServer()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = sheet.popoverPresentationController {   // iPad
            popover.sourceView = view
            popover.sourceRect = CGRect(origin: gesture.location(in: view), size: .zero)
        }
        present(sheet, animated: true)
    }

    // MARK: - Helpers

    private func isAppURL(_ url: URL) -> Bool {
        url.host?.lowercased() == serverURL.host?.lowercased() && effectivePort(url) == effectivePort(serverURL)
    }

    private func effectivePort(_ url: URL) -> Int {
        url.port ?? (url.scheme?.lowercased() == "https" ? 443 : 80)
    }

    private func presentIfPossible(_ controller: UIViewController, otherwise fallback: () -> Void) {
        guard viewIfLoaded?.window != nil, presentedViewController == nil else {
            fallback()
            return
        }
        present(controller, animated: true)
    }

    private func handleNavigationError(_ error: Error) {
        webView.scrollView.refreshControl?.endRefreshing()
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return }
        // 102 = "frame load interrupted": normal when a link turns into a download.
        if nsError.domain != NSURLErrorDomain && nsError.code == 102 { return }
        errorView.show(message: Self.friendlyMessage(for: nsError))
    }

    private static func friendlyMessage(for error: NSError) -> String {
        guard error.domain == NSURLErrorDomain else { return error.localizedDescription }
        switch error.code {
        case NSURLErrorNotConnectedToInternet:
            return "This iPhone is offline. Check Wi-Fi or mobile data."
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost, NSURLErrorTimedOut,
             NSURLErrorNetworkConnectionLost, NSURLErrorDNSLookupFailed:
            return "The server didn't answer. If Innovoprism is only reachable over Tailscale, open the Tailscale app, make sure it's connected, then try again."
        case NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateUntrusted,
             NSURLErrorServerCertificateHasBadDate, NSURLErrorServerCertificateNotYetValid,
             NSURLErrorServerCertificateHasUnknownRoot:
            return "iOS doesn't trust this server's HTTPS certificate. Use the server's Tailscale HTTPS name (…ts.net) or its plain http:// address."
        default:
            return error.localizedDescription
        }
    }
}

// MARK: - Navigation

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.shouldPerformDownload {       // <a download>
            decisionHandler(.download)
            return
        }
        guard let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() else {
            decisionHandler(.allow)
            return
        }

        // tel:, mailto:, whatsapp:, etc. -> hand to iOS
        let webSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript"]
        if !webSchemes.contains(scheme) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        // Tapped links to other websites open in Safari, not inside the app.
        let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
        if (scheme == "http" || scheme == "https"),
           isMainFrame,
           navigationAction.navigationType == .linkActivated,
           !isAppURL(url) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let http = navigationResponse.response as? HTTPURLResponse,
           let disposition = http.value(forHTTPHeaderField: "Content-Disposition"),
           disposition.lowercased().contains("attachment") {
            decisionHandler(.download)
            return
        }
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .download)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        errorView.isHidden = true
        webView.scrollView.refreshControl?.endRefreshing()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()   // iOS reclaimed memory while in background
    }
}

// MARK: - Dialogs, new windows, camera/mic

extension WebViewController: WKUIDelegate {

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        // target="_blank" / window.open: app pages load here, other sites go to Safari.
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            let scheme = url.scheme?.lowercased() ?? ""
            if (scheme == "http" || scheme == "https") && !isAppURL(url) {
                UIApplication.shared.open(url)
            } else {
                webView.load(navigationAction.request)
            }
        }
        return nil
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        presentIfPossible(alert) { completionHandler() }
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        presentIfPossible(alert) { completionHandler(false) }
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { field in field.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak alert] _ in
            completionHandler(alert?.textFields?.first?.text ?? "")
        })
        presentIfPossible(alert) { completionHandler(nil) }
    }

    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        // Our own server: don't ask twice (iOS still asks once for camera/mic access).
        let ours = origin.host.lowercased() == (serverURL.host ?? "").lowercased()
        decisionHandler(ours ? .grant : .prompt)
    }
}

// MARK: - Downloads -> share sheet (Save to Files, AirDrop, WhatsApp, ...)

extension WebViewController: WKDownloadDelegate {

    func download(_ download: WKDownload,
                  decideDestinationUsing response: URLResponse,
                  suggestedFilename: String,
                  completionHandler: @escaping (URL?) -> Void) {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let name = suggestedFilename.isEmpty ? "download" : suggestedFilename
        let destination = folder.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: destination)
        downloadDestinations[ObjectIdentifier(download)] = destination
        completionHandler(destination)
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let file = downloadDestinations.removeValue(forKey: ObjectIdentifier(download)) else { return }
        let share = UIActivityViewController(activityItems: [file], applicationActivities: nil)
        if let popover = share.popoverPresentationController {   // iPad
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        presentIfPossible(share) {}
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        downloadDestinations.removeValue(forKey: ObjectIdentifier(download))
        let alert = UIAlertController(title: "Download failed", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentIfPossible(alert) {}
    }
}

// MARK: - Let the two-finger menu gesture coexist with page scrolling

extension WebViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
