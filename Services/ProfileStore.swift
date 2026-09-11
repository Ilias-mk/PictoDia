import Foundation

/// Saves and loads the person's profile in a local file.
nonisolated struct ProfileStore {

    private var url: URL {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return folder.appendingPathComponent("profile.txt")
    }

    /// Returns the saved profile, or an empty string if there isn't one yet.
    func load() -> String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    /// Overwrites the saved profile.
    func save(_ text: String) {
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }
}
