import SwiftUI

struct SettingsView: View {
    @AppStorage("appColorScheme") private var appColorScheme: String = "system"
    @Environment(\.dismiss) private var dismiss

    // MARK: - Version / Build Info
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationView {
            Form {

                // MARK: - Support Section
                Section(header: Text("Support")) {

                    Link("Visit Website",
                         destination: URL(string: "https://vitalcodetechlabs.com")!)

                    Link("Privacy Policy",
                         destination: URL(string: "https://vitalcodetechlabs.com/privacy")!)

                    Button("Email Developer") {
                        sendEmail()
                    }

                    Button("Rate This App") {
                        rateApp()
                    }
                }

                // MARK: - Appearance Section
                Section(header: Text("Appearance")) {
                    Picker("Color Mode", selection: $appColorScheme) {
                        Text("System Default").tag("system")
                        Text("Light Mode").tag("light")
                        Text("Dark Mode").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: - App Info Section
                Section(header: Text("App Info")) {
                    HStack {
                        Text("App Name")
                        Spacer()
                        Text("iBudgetBuddy")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundColor(.secondary)
                    }
                }

            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Email Developer
    private func sendEmail() {
        let email = "mailto:vitalcodetechlabs@gmail.com"
        if let url = URL(string: email) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Rate App
    private func rateApp() {
        // Replace YOUR_APP_ID with your real App Store ID once you have it
        let appID = "6757996353"
        let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")!

        UIApplication.shared.open(url)
    }
}
