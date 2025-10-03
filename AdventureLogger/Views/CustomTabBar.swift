//
//  CustomTabBar.swift
//

import SwiftUI
import UIKit

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @State private var showingAddPlace = false

    var body: some View {
        HStack(spacing: 0) {
            // Adventures Tab
            TabBarButton(
                icon: "list.bullet",
                title: "Adventures",
                isSelected: selectedTab == 0
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 0
                }
            }

            // Map Tab
            TabBarButton(
                icon: "map.fill",
                title: "Map",
                isSelected: selectedTab == 1
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 1
                }
            }

            // Center Add Button (Featured)
            Button(action: {
                showingAddPlace = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -20)
            .padding(.horizontal, 20)

            // Discover Tab
            TabBarButton(
                icon: "magnifyingglass",
                title: "Discover",
                isSelected: selectedTab == 2
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 2
                }
            }

            // Settings Tab
            TabBarButton(
                icon: "gear",
                title: "Settings",
                isSelected: selectedTab == 3
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 3
                }
            }
        }
        .frame(height: 60)
        .background(
            ZStack {
                // Frosted glass effect
                BlurView(style: .systemMaterial)

                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color(.systemBackground).opacity(0.95),
                        Color(.systemBackground).opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .overlay(
            // Top border with gradient
            LinearGradient(
                colors: [
                    Color.gray.opacity(0.2),
                    Color.gray.opacity(0.1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 0.5),
            alignment: .top
        )
        .sheet(isPresented: $showingAddPlace) {
            AddPlaceView()
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 24 : 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .accentColor : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .accentColor : .gray)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Blur View for frosted glass effect
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(0))
    }
    .background(Color.gray.opacity(0.3))
}
