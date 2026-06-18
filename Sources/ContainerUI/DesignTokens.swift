import SwiftUI

// MARK: - Design Tokens

/// Centralized design constants for consistent visual language across the app.
enum DT {

    // MARK: Corner Radii
    static let cardRadius: CGFloat = 16
    static let smallCardRadius: CGFloat = 10
    static let badgeRadius: CGFloat = 6

    // MARK: Spacing
    static let sectionSpacing: CGFloat = 16
    static let cardSpacing: CGFloat = 14
    static let innerSpacing: CGFloat = 8

    // MARK: Shadows
    static func cardShadow() -> some View {
        Color.clear
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: Gradients
    enum Gradient {
        static let blue = LinearGradient(
            colors: [Color(red: 0.25, green: 0.60, blue: 0.96), Color(red: 0.30, green: 0.85, blue: 0.93)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let purple = LinearGradient(
            colors: [Color(red: 0.55, green: 0.35, blue: 0.98), Color(red: 0.95, green: 0.45, blue: 0.75)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let green = LinearGradient(
            colors: [Color(red: 0.20, green: 0.78, blue: 0.55), Color(red: 0.30, green: 0.92, blue: 0.70)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let red = LinearGradient(
            colors: [Color(red: 0.90, green: 0.31, blue: 0.31), Color(red: 0.98, green: 0.50, blue: 0.45)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let orange = LinearGradient(
            colors: [Color(red: 0.95, green: 0.62, blue: 0.22), Color(red: 1.00, green: 0.80, blue: 0.40)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    // MARK: Title Font
    static func pageTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .bold, design: .rounded))
    }
}

// MARK: - Gradient Icon Badge

/// A rounded square with a gradient background holding an SF Symbol.
struct GradientIcon: View {
    let systemName: String
    let gradient: LinearGradient
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(gradient)
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}
