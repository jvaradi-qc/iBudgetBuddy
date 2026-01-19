import SwiftUI

/// A SwiftUI environment key that allows the app to know when it is running under UI tests.
private struct UITestModeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// Indicates whether the app is currently running in UI test mode.
    var uiTestMode: Bool {
        get { self[UITestModeKey.self] }
        set { self[UITestModeKey.self] = newValue }
    }
}
