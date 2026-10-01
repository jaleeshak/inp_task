import SwiftUI

/// Bridges the UIKit web view controller into SwiftUI.
struct WebContainerView: UIViewControllerRepresentable {
    let serverURL: URL
    let onChangeServer: () -> Void

    func makeUIViewController(context: Context) -> WebViewController {
        WebViewController(serverURL: serverURL, onChangeServer: onChangeServer)
    }

    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {}
}
