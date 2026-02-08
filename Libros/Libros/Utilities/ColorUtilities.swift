import SwiftUI

extension Color {
    /// Creates a Color from a hex string (e.g., "#FF6B6B" or "FF6B6B")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hex.count {
        case 6: // RGB
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8: // RGBA
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (128, 128, 128, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

/// Preset tag color palette
enum TagColors {
    static let presets: [(name: String, hex: String)] = [
        ("Red", "#FF6B6B"),
        ("Coral", "#FF8A65"),
        ("Orange", "#FFA726"),
        ("Amber", "#FFCA28"),
        ("Yellow", "#FFEAA7"),
        ("Lime", "#C6FF00"),
        ("Green", "#66BB6A"),
        ("Teal", "#4ECDC4"),
        ("Cyan", "#26C6DA"),
        ("Blue", "#45B7D1"),
        ("Indigo", "#5C6BC0"),
        ("Purple", "#AB47BC"),
        ("Pink", "#EC407A"),
        ("Rose", "#F48FB1"),
        ("Mint", "#96CEB4"),
        ("Sage", "#81C784"),
    ]

    static let defaultHex = "#45B7D1"
}
