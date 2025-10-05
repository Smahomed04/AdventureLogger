//
//  SyncStatusView.swift
//  AdventureLogger
//

import SwiftUI

struct SyncStatusIndicator: View {
    @StateObject private var syncManager = CloudSyncManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            // Animated icon
            ZStack {
                if case .syncing = syncManager.syncStatus {
                    Image(systemName: syncManager.syncStatus.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(syncManager.syncStatus.description == "Syncing..." ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 2)
                                .repeatForever(autoreverses: false),
                            value: syncManager.syncStatus.description
                        )
                } else {
                    Image(systemName: syncManager.syncStatus.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(statusColor)
                }
            }

            Text(syncManager.syncStatus.description)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            if let lastSync = syncManager.lastSyncDate {
                Text("• \(timeAgo(lastSync))")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
    }

    private var statusColor: Color {
        switch syncManager.syncStatus {
        case .idle:
            return .secondary
        case .syncing:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }

    private var backgroundColor: Color {
        switch syncManager.syncStatus {
        case .idle:
            return Color(.systemGray6).opacity(0.5)
        case .syncing:
            return Color.blue.opacity(0.1)
        case .success:
            return Color.green.opacity(0.1)
        case .error:
            return Color.red.opacity(0.1)
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        }
    }
}

struct CloudSyncButton: View {
    @StateObject private var syncManager = CloudSyncManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: {
            syncManager.manualSync()
        }) {
            HStack(spacing: 8) {
                if case .syncing = syncManager.syncStatus {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text("Sync Now")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .shadow(
                color: colorScheme == .dark ? Color.clear : Color.blue.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(syncManager.syncStatus.description == "Syncing...")
    }
}

struct NetworkStatusBanner: View {
    @StateObject private var syncManager = CloudSyncManager.shared

    var body: some View {
        if !syncManager.isOnline {
            HStack(spacing: 10) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 14, weight: .semibold))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Offline Mode")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text("Changes will sync when online")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.orange.opacity(0.15))
        }
    }
}
