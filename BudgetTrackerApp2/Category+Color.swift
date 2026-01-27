import SwiftUI

extension Category {
    var color: Color {
        if let hex = colorHex, let ui = UIColor(hex: hex) {
            return Color(ui)
        }
        return .gray
    }
}
