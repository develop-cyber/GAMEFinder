import SwiftUI

@main
struct GAMEFinderApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .task { await store.loadGames() }
        }
    }
}
