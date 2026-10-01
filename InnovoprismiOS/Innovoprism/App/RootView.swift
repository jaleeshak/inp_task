import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        if let url = settings.serverURL {
            WebContainerView(serverURL: url, onChangeServer: { settings.clearServer() })
                .id(url)                 // new server -> fresh web view
                .ignoresSafeArea()       // the UIKit controller handles safe areas & keyboard itself
        } else {
            SetupView()
        }
    }
}
