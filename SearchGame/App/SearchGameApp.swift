import SwiftUI

@main
struct SearchGameApp: App {
    var body: some Scene {
        WindowGroup {
            GameViewControllerRepresentable()
                .ignoresSafeArea()
        }
    }
}
