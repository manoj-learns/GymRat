import SwiftUI

extension Color {
    static let gymPrimary    = Color(red: 0.0,  green: 0.78, blue: 1.0)   // Cyan
    static let gymPurple     = Color(red: 0.6,  green: 0.2,  blue: 1.0)   // Purple
    static let gymOrange     = Color(red: 1.0,  green: 0.4,  blue: 0.0)   // Orange
    static let gymGreen      = Color(red: 0.18, green: 0.88, blue: 0.45)  // Green
    static let gymRed        = Color(red: 1.0,  green: 0.27, blue: 0.27)  // Red
    static let gymYellow     = Color(red: 1.0,  green: 0.83, blue: 0.0)   // Yellow
    static let gymBackground = Color(red: 0.07, green: 0.07, blue: 0.09)  // Near black
    static let gymCard       = Color(red: 0.13, green: 0.13, blue: 0.16)  // Dark card
    static let gymCard2      = Color(red: 0.18, green: 0.18, blue: 0.22)  // Slightly lighter card
}

extension LinearGradient {
    static let gymCyan = LinearGradient(
        colors: [Color(red: 0.0, green: 0.78, blue: 1.0), Color(red: 0.0, green: 0.5, blue: 0.9)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let gymPurpleGrad = LinearGradient(
        colors: [Color(red: 0.7, green: 0.3, blue: 1.0), Color(red: 0.4, green: 0.1, blue: 0.8)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let gymOrangeGrad = LinearGradient(
        colors: [Color(red: 1.0, green: 0.6, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let gymGreenGrad = LinearGradient(
        colors: [Color(red: 0.18, green: 0.88, blue: 0.45), Color(red: 0.0, green: 0.65, blue: 0.3)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct GymCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.gymCard)
            .cornerRadius(16)
    }
}

extension View {
    func gymCard() -> some View { modifier(GymCard()) }
}

// Extend ShapeStyle so `.gymPrimary` etc. resolve in any foregroundStyle / tint context
extension ShapeStyle where Self == Color {
    static var gymPrimary:    Color { .init(red: 0.0,  green: 0.78, blue: 1.0) }
    static var gymPurple:     Color { .init(red: 0.6,  green: 0.2,  blue: 1.0) }
    static var gymOrange:     Color { .init(red: 1.0,  green: 0.4,  blue: 0.0) }
    static var gymGreen:      Color { .init(red: 0.18, green: 0.88, blue: 0.45) }
    static var gymRed:        Color { .init(red: 1.0,  green: 0.27, blue: 0.27) }
    static var gymYellow:     Color { .init(red: 1.0,  green: 0.83, blue: 0.0) }
    static var gymBackground: Color { .init(red: 0.07, green: 0.07, blue: 0.09) }
    static var gymCard:       Color { .init(red: 0.13, green: 0.13, blue: 0.16) }
    static var gymCard2:      Color { .init(red: 0.18, green: 0.18, blue: 0.22) }
}
