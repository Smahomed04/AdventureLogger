//
//  DesignSystem.swift
//  AdventureLogger
//

import SwiftUI

// MARK: - Color Palette
extension Color {
    // Vibrant gradients for categories (adjusted for dark mode)
    static let beachGradient = [Color(hex: "5BA3F5"), Color(hex: "60D5FF")]
    static let hikeGradient = [Color(hex: "66BB3F"), Color(hex: "B8F073")]
    static let activityGradient = [Color(hex: "FF7B7B"), Color(hex: "FFC357")]
    static let restaurantGradient = [Color(hex: "F75C4C"), Color(hex: "FF7BAD")]
    static let worshipGradient = [Color(hex: "9B59B6"), Color(hex: "6C5CE7")]
    static let otherGradient = [Color(hex: "B865FF"), Color(hex: "FC5899")]

    // App accent colors (adaptive)
    static let primaryAccent = Color(hex: "FF6B6B")
    static let secondaryAccent = Color(hex: "4ECDC4")

    // Adaptive background colors
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)

    // Helper to create Color from hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradient Helpers
struct CategoryGradient {
    static func forCategory(_ category: String) -> LinearGradient {
        let colors: [Color]
        switch category {
        case "Beach":
            colors = Color.beachGradient
        case "Hike":
            colors = Color.hikeGradient
        case "Activity":
            colors = Color.activityGradient
        case "Restaurant":
            colors = Color.restaurantGradient
        case "Place of Worship":
            colors = Color.worshipGradient
        default:
            colors = Color.otherGradient
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Custom View Modifiers
struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.1),
                        radius: 10,
                        x: 0,
                        y: 4
                    )
            )
    }
}

struct FloatingButtonStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                Circle()
                    .fill(Color.cardBackground)
                    .shadow(
                        color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.15),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
    }
}

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - View Extensions
extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    func floatingButton() -> some View {
        modifier(FloatingButtonStyle())
    }

    func pulse() -> some View {
        modifier(PulseAnimation())
    }

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Reusable Components
struct GradientHeader: View {
    let title: String
    let subtitle: String?
    let gradient: LinearGradient

    init(title: String, subtitle: String? = nil, gradient: LinearGradient) {
        self.title = title
        self.subtitle = subtitle
        self.gradient = gradient
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(gradient)
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let gradient: LinearGradient

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(gradient)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassCard()
    }
}

struct ModernButton: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gradient)
            .cornerRadius(14)
            .shadow(
                color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.2),
                radius: 8,
                x: 0,
                y: 4
            )
        }
    }
}
