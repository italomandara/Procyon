//
//  UsrDefaults.swift
//  Procyon
//
//  Created by Italo Mandara on 24/02/2026.
//

import Foundation

let suiteName = "group.com.italomandara.procyon"

func resolvePersistedFolders() -> [URL] {
    let groupDefaults = UserDefaults(suiteName: suiteName)!
    let bookmarks = groupDefaults.array(forKey: "steamLibraryBookmarks") as? [Data] ?? []
    var urls: [URL] = []
    for data in bookmarks {
        var isStale = false
        if let url = try? URL(resolvingBookmarkData: data,
                              options: [.withSecurityScope],
                              relativeTo: nil,
                              bookmarkDataIsStale: &isStale),
           !isStale {
            urls.append(url)
        }
    }
    return urls
}

func removePersistedFolderAccess(url: URL) {
    let key = "steamLibraryBookmarks"
    let groupDefaults = UserDefaults(suiteName: suiteName)!
    let bookmarks = groupDefaults.array(forKey: key) as? [Data] ?? []

    let filtered: [Data] = bookmarks.filter { data in
        var isStale = false
        guard let resolved = try? URL(resolvingBookmarkData: data,
                                      options: [.withSecurityScope],
                                      relativeTo: nil,
                                      bookmarkDataIsStale: &isStale),
              !isStale else {
            // Drop stale or unresolvable bookmarks
            return false
        }
        // Compare standardized file URLs to avoid minor representation differences
        return resolved.standardizedFileURL != url.standardizedFileURL
    }

    groupDefaults.set(filtered, forKey: key)
}

func resetPersistedFolderAccess() {
    let key = "steamLibraryBookmarks"
    let groupDefaults = UserDefaults(suiteName: suiteName)!

    groupDefaults.removeObject(forKey: key)
}

func persistFolderAccess(url: URL) throws {
    /**
     Since we're sandboxed we need to persist the permission to access the folders afterwards, when the apps reads the folders again
     */
    let bookmark = try url.bookmarkData(options: [.withSecurityScope],
                                        includingResourceValuesForKeys: nil,
                                        relativeTo: nil)
    let groupDefaults = UserDefaults(suiteName: suiteName)!
    var bookmarks = groupDefaults.array(forKey: "steamLibraryBookmarks") as? [Data] ?? []
    bookmarks.append(bookmark)
    groupDefaults.set(bookmarks, forKey: "steamLibraryBookmarks")
}

func namespacedKey(_ namespace: String, _ key: String) -> String {
    "\(namespace).\(key)"
}

func persistUsrDefData(key: String, data: Codable) {
    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(data) else { return }
    let groupDefaults = UserDefaults(suiteName: suiteName)!
    groupDefaults.set(data, forKey: key)
}

func readUsrDefData<T: Decodable>(key: String, type: T.Type = T.self) -> T? {
    let groupDefaults = UserDefaults(suiteName: suiteName)!
    guard let data = groupDefaults.value(forKey: key) as? Data else {
        console.error("couldn't get data for \(key)")
        return nil
    }
    do {
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        console.error("couldn't decode data for \(key)")
        return nil
    }
}


func persistUsrDefOptionString(key: String, value: String) {
    let groupDefaults = UserDefaults(suiteName: suiteName)!
    groupDefaults.set(value, forKey: key)
}

func readUsrDefOptionString(key: String, defaultValue: String = "") -> String {
    let value = UserDefaults(suiteName: suiteName)!.value(forKey: key) as? String
    return value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? value! : defaultValue
}

func deleteUsrDefOptionStartsWith(prefix: String) {
    guard let defaults = UserDefaults(suiteName: suiteName) else { return }
    let dict = defaults.dictionaryRepresentation()

    for key in dict.keys where key.hasPrefix(prefix) {
        defaults.removeObject(forKey: key)
    }
}
