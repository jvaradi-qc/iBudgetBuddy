import SwiftUI

@main
struct BudgetTrackerApp2App: App {
    @AppStorage("appColorScheme") private var appColorScheme: String = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.horizontalSizeClass, .compact)
                .environment(
                    \.uiTestMode,
                    ProcessInfo.processInfo.environment["UITEST_MODE"] == "1"
                )
                .preferredColorScheme(
                    appColorScheme == "light" ? .light :
                    appColorScheme == "dark" ? .dark : nil
                )
        }
    }
}

