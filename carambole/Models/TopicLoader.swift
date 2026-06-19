import Foundation

struct TopicManifest: Codable {
    let topicFiles: [String]
}

enum TopicLoader {
    /// Seeds grammar topics from bundled JSON if the database has no topics yet.
    static func seedIfNeeded() {
        let existingCount = DataManager.shared.topicCount()
        print("TopicLoader: Checking topic count, found \(existingCount) topics")
        if existingCount > 0 {
            print("TopicLoader: Database already has topics, skipping seeding")
            return
        }

        print("TopicLoader: No topics found, loading from manifest...")
        guard let manifestURL = bundleURL(forResource: "manifest", withExtension: "json") else {
            print("Error: Could not find manifest.json in bundle")
            return
        }

        let manifest: TopicManifest
        do {
            print("TopicLoader: Loading manifest from: \(manifestURL.path)")
            let data = try Data(contentsOf: manifestURL)
            manifest = try JSONDecoder().decode(TopicManifest.self, from: data)
            print("TopicLoader: Manifest lists \(manifest.topicFiles.count) topic file(s)")
        } catch {
            print("Error loading manifest: \(error)")
            return
        }

        for fileName in manifest.topicFiles {
            let resource = (fileName as NSString).deletingPathExtension
            let ext = (fileName as NSString).pathExtension
            guard let topicURL = bundleURL(forResource: resource, withExtension: ext) else {
                print("Error: Could not find topic file \(fileName) in bundle")
                continue
            }

            do {
                print("TopicLoader: Loading topic from: \(topicURL.path)")
                let data = try Data(contentsOf: topicURL)
                let topic = try JSONDecoder().decode(GrammarTopic.self, from: data)
                print("TopicLoader: Decoded topic '\(topic.title)' with \(topic.exercises.count) exercises")
                DataManager.shared.upsertTopic(topic)
            } catch {
                print("Error loading topic \(fileName): \(error)")
            }
        }
    }

    /// Resolves a bundled resource URL, trying the `Topics` subdirectory first and
    /// falling back to the flattened bundle root (synchronized groups may flatten resources).
    private static func bundleURL(forResource resource: String, withExtension ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: resource, withExtension: ext, subdirectory: "Topics") {
            print("TopicLoader: Resolved \(resource).\(ext) in Topics/ subdirectory")
            return url
        }
        if let url = Bundle.main.url(forResource: resource, withExtension: ext) {
            print("TopicLoader: Resolved \(resource).\(ext) at bundle root (flattened)")
            return url
        }
        print("TopicLoader: Could not resolve \(resource).\(ext) in subdirectory or bundle root")
        return nil
    }
}
