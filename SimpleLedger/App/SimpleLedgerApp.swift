import SwiftUI

@main
struct SimpleLedgerApp: App {
    @StateObject private var store = LedgerStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .tint(Color.brandBlue)
        }
    }
}
