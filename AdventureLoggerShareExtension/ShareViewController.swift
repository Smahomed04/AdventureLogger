import UIKit
import Social
import UniformTypeIdentifiers

// MARK: - Shared helpers

fileprivate struct SharedPackage: Codable {
    var title: String           // From contentText or filename or page title
    var subtitle: String?       // e.g. host or “From Photos”
    var text: String?           // Raw shared text
    var url: String?            // URL if shared
    var imagePath: String?
    var createdAt: Date
}

fileprivate enum SharedIO {
    static let appGroupID = "group.com.shaiyankhan.AdventureLogger"
    static let inboxDirName = "ShareInbox"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    static func inboxURL() -> URL? {
        guard let base = containerURL else { return nil }
        let inbox = base.appendingPathComponent(inboxDirName, isDirectory: true)
        try? FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        return inbox
    }

    static func write(_ pkg: SharedPackage) throws -> URL {
        guard let inbox = inboxURL() else { throw NSError(domain: "ShareIO", code: 1) }
        let name = "pkg-\(UUID().uuidString).json"
        let url = inbox.appendingPathComponent(name)
        let data = try JSONEncoder().encode(pkg)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func saveImage(_ data: Data, suggested: String?) -> String? {
        guard let inbox = inboxURL() else { return nil }
        let fname = (suggested?.isEmpty == false ? suggested! : "image-\(UUID().uuidString).jpg")
        let url = inbox.appendingPathComponent(fname)
        do {
            try data.write(to: url, options: .atomic)
            return url.lastPathComponent
        } catch { return nil }
    }
}



final class ShareViewController: SLComposeServiceViewController {

    private var pendingItems: [NSItemProvider] = []

    override func isContentValid() -> Bool {
      
        return true
    }

    override func didSelectPost() {
      
        guard let ctxItems = self.extensionContext?.inputItems as? [NSExtensionItem] else {
            self.extensionContext?.completeRequest(returningItems: nil)
            return
        }

        var titleText = self.contentText?.trimmingCharacters(in: .whitespacesAndNewlines)
        var subtitle: String?
        var sharedURL: String?
        var sharedText: String? = (titleText?.isEmpty ?? true) ? nil : titleText
        var imageSavedFilename: String?

        let group = DispatchGroup()

        for item in ctxItems {
            guard let providers = item.attachments else { continue }
            for provider in providers {
                // URL
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { obj, _ in
                        if let url = obj as? URL {
                            sharedURL = url.absoluteString
                            subtitle = subtitle ?? url.host
                            if (titleText?.isEmpty ?? true) {
                                titleText = url.deletingPathExtension().lastPathComponent.capitalized
                            }
                        }
                        group.leave()
                    }
                    continue
                }

                // Plain text
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { obj, _ in
                        if let t = obj as? String, !t.isEmpty {
                            sharedText = (sharedText?.isEmpty ?? true) ? t : (sharedText! + "\n" + t)
                            if (titleText?.isEmpty ?? true) { titleText = String(t.prefix(32)) }
                        }
                        group.leave()
                    }
                    continue
                }

                // Image (jpeg/png/heic)
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    group.enter()
                    provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                        if let data, let fn = SharedIO.saveImage(data, suggested: "photo-\(Int(Date().timeIntervalSince1970)).jpg") {
                            imageSavedFilename = fn
                            subtitle = subtitle ?? "From Photos"
                        }
                        group.leave()
                    }
                    continue
                }
            }
        }

        group.notify(queue: .main) {
            let pkg = SharedPackage(
                title: (titleText?.isEmpty ?? true) ? "New Adventure" : titleText!,
                subtitle: subtitle,
                text: sharedText,
                url: sharedURL,
                imagePath: imageSavedFilename,
                createdAt: Date()
            )

            // Write to app group
            _ = try? SharedIO.write(pkg)

            // Optionally deep-link into the host app:
            if let openURL = URL(string: "adventurelogger://import") {
                self.extensionContext?.open(openURL, completionHandler: { _ in
                    self.extensionContext?.completeRequest(returningItems: nil)
                })
            } else {
                self.extensionContext?.completeRequest(returningItems: nil)
            }
        }
    }

    override func configurationItems() -> [Any]! {
        
        return []
    }
}
