import SwiftUI

@main
struct SazonExpressApp: App {
    @StateObject var store = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentRoot()
                .environmentObject(store)
                .preferredColorScheme(store.isDarkMode ? .dark : .light)
        }
    }
}

struct ContentRoot: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        if store.isUserLoggedIn || store.isAdminLoggedIn {
            MainTabView()
        } else {
            LoginView()
        }
    }
}
