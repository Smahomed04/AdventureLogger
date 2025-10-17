import Foundation

public struct WidgetAdventureSnapshot: Codable, Equatable {
    public var title: String
    public var subtitle: String?
    public var date: Date
    public var metric: String?

    public init(title: String,
                subtitle: String? = nil,
                date: Date,
                metric: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.date = date
        self.metric = metric
    }
}

public enum WidgetCache {
    public static let appGroupID = "group.com.shaiyankhan.AdventureLogger"
    private static let key = "widget.latestAdventure"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    public static func save(_ snapshot: WidgetAdventureSnapshot) {
        guard let defaults else { return }
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(snapshot) {
            defaults.set(data, forKey: key)
        }
    }

    public static func load() -> WidgetAdventureSnapshot? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: key) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(WidgetAdventureSnapshot.self, from: data)
    }

    public static func clear() {
        defaults?.removeObject(forKey: key)
    }
}
