import WidgetKit
import SwiftUI

// MARK: - Entry

struct AdventureEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetAdventureSnapshot?
}

// Sample used for placeholder/preview
private let sample = WidgetAdventureSnapshot(
    title: "Sunset Trail",
    subtitle: "Blue Mountains",
    date: Date(),
    metric: "9.3 km"
)

// MARK: - Provider

struct AdventureProvider: TimelineProvider {
    func placeholder(in context: Context) -> AdventureEntry {
        AdventureEntry(date: Date(), snapshot: sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (AdventureEntry) -> Void) {
        completion(AdventureEntry(date: Date(), snapshot: WidgetCache.load() ?? sample))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AdventureEntry>) -> Void) {
        let snap = WidgetCache.load()
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [AdventureEntry(date: Date(), snapshot: snap)],
                            policy: .after(refresh)))
    }
}

// MARK: - Theme Helpers

private struct WidgetTheme {
    static let corner: CGFloat = 16

    static let gradient = LinearGradient(
        colors: [
            Color(.systemTeal).opacity(0.35),
            Color(.systemBlue).opacity(0.35),
            Color(.systemIndigo).opacity(0.35)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func metricPill(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.15)))
    }
}

// MARK: - Small Layout

private struct SmallCard: View {
    let s: WidgetAdventureSnapshot
    let date: Date

    var body: some View {
        ZStack {
            WidgetTheme.gradient
                .clipShape(RoundedRectangle(cornerRadius: WidgetTheme.corner, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                // Top row: icon + metric
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .symbolRenderingMode(.hierarchical)
                    Spacer(minLength: 0)
                    if let m = s.metric { WidgetTheme.metricPill(m) }
                }

                // Title
                Text(s.title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)

                // Subtitle
                if let sub = s.subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                // Time
                Text(date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
        }
        // Keeps system widget chrome tidy
        .containerBackground(.clear, for: .widget)
        .widgetAccentable()
    }
}

// MARK: - Medium Layout

private struct MediumCard: View {
    let s: WidgetAdventureSnapshot
    let date: Date

    var body: some View {
        ZStack {
            WidgetTheme.gradient
                .clipShape(RoundedRectangle(cornerRadius: WidgetTheme.corner, style: .continuous))

            HStack(spacing: 12) {
                // Left “badge” block
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12)))
                    Image(systemName: "figure.hiking")
                        .font(.system(size: 28, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                }
                .frame(width: 56, height: 56)

                // Right details
                VStack(alignment: .leading, spacing: 6) {
                    Text(s.title)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)

                    if let sub = s.subtitle {
                        Text(sub)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        if let m = s.metric { WidgetTheme.metricPill(m) }
                        WidgetTheme.metricPill(DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short))
                    }
                    .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
        }
        .containerBackground(.clear, for: .widget)
        .widgetAccentable()
    }
}

// MARK: - Main View (adapts per family)

struct AdventureWidgetView: View {
    let entry: AdventureEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let s = entry.snapshot {
                switch family {
                case .systemSmall:
                    SmallCard(s: s, date: entry.date)
                default:
                    MediumCard(s: s, date: entry.date)
                }
            } else {
                // Fallback/empty state
                ZStack {
                    WidgetTheme.gradient
                        .clipShape(RoundedRectangle(cornerRadius: WidgetTheme.corner, style: .continuous))
                    VStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                        Text("No recent adventure")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .containerBackground(.clear, for: .widget)
            }
        }
        // Deep-link into your app if you’ve registered the URL scheme
        .widgetURL(URL(string: "adventurelogger://latest"))
        .contentMargins(.all, 0) // lets our rounded container fill nicely
    }
}

// MARK: - Widget

struct AdventureLoggerWidget: Widget {
    let kind: String = "AdventureLoggerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AdventureProvider()) { entry in
            AdventureWidgetView(entry: entry)
        }
        .configurationDisplayName("Latest Adventure")
        .description("Beautiful glance of your most recent trip, distance and time.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews shown in the add-widget gallery

#Preview(as: .systemSmall) {
    AdventureLoggerWidget()
} timeline: {
    AdventureEntry(date: .now, snapshot: sample)
}

#Preview(as: .systemMedium) {
    AdventureLoggerWidget()
} timeline: {
    AdventureEntry(date: .now, snapshot: sample)
}
