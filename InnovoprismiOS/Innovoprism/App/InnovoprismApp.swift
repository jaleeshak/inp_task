import SwiftUI

@main
struct InnovoprismApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
        }
    }
}
