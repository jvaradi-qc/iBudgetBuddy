import SwiftUI

@main
struct BudgetTrackerApp2App: App {
    @AppStorage("appColorScheme") private var appColorScheme: String = "system"

    var body: some Scene {
        WindowGroup {
            let isUITest = ProcessInfo.processInfo.environment["UITEST_MODE"] == "1"

            ContentView()
                // Preserve your forced-compact layout EXCEPT during UI tests
                .environment(\.horizontalSizeClass, isUITest ? nil : .compact)
                .environment(\.uiTestMode, isUITest)
                .preferredColorScheme(
                    appColorScheme == "light" ? .light :
                    appColorScheme == "dark" ? .dark : nil
                )
        }
    }
}
