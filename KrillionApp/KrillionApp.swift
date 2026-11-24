import SwiftUI

@main
struct KrillionApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
                // The view controller handles the keyboard itself, so SwiftUI
                // must not also resize or shift it.
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
        }
    }
}

struct GameView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GameViewController {
        GameViewController()
    }

    func updateUIViewController(_ controller: GameViewController, context: Context) {}
}
