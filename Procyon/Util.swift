//
//  Util.swift
//  Procyon
//
//  Created by Italo Mandara on 03/02/2026.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine

func openFolderSelectorPanel(type: UTType = .folder) -> URL? {
    let panel = NSOpenPanel()
    panel.title = "Select a Steam library folder (steamapps)";
    panel.allowsMultipleSelection = false;
    panel.canChooseDirectories = true;
    panel.allowedContentTypes = [type]
    return panel.runModal() == .OK ? panel.url?.absoluteURL : nil
}

func persistFolderAccess(url: URL) throws {
    /**
     Since we're sandboxed we need to persist the permission to access the folders afterwards, when the apps reads the folders again
     */
    let bookmark = try url.bookmarkData(options: [.withSecurityScope],
                                        includingResourceValuesForKeys: nil,
                                        relativeTo: nil)
    let groupDefaults = UserDefaults(suiteName: "group.com.italomandara.procyon")!
    var bookmarks = groupDefaults.array(forKey: "steamLibraryBookmarks") as? [Data] ?? []
    bookmarks.append(bookmark)
    groupDefaults.set(bookmarks, forKey: "steamLibraryBookmarks")
}

func persistUsrDefOptionString(key: String, value: String) {
    let groupDefaults = UserDefaults(suiteName: "group.com.italomandara.procyon")!
    groupDefaults.set(value, forKey: key)
}

func readUsrDefOptionString(key: String) -> String? {
    return UserDefaults(suiteName: "group.com.italomandara.procyon")!.value(forKey: key) as? String
}

func resolvePersistedFolders() -> [URL] {
    let groupDefaults = UserDefaults(suiteName: "group.com.italomandara.procyon")!
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
    let groupDefaults = UserDefaults(suiteName: "group.com.italomandara.procyon")!
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

func withSecurityScope<T>(for url: URL, _ body: () throws -> T) rethrows -> T? {
    guard url.startAccessingSecurityScopedResource() else { return nil }
    defer { url.stopAccessingSecurityScopedResource() }
    return try body()
}

func addSteamFolderPaths(_ url: URL) {
    do {
        if (try scanSteamFolder(dest: url).isEmpty) {
            print("Folder is empty")
            return
        }
    } catch {
        print("Failed to validate steam folder")
        print(error)
    }
    do {
        try persistFolderAccess(url: url)
    } catch {
        print("Failed to save steam folder")
        print(error)
    }
}

func removeSteamFolderPath(_ path: String) {
    let url = URL(string: path)!
    removePersistedFolderAccess(url: url)
}

func getSteamFolderPaths() -> [String] {
    return resolvePersistedFolders().map { $0.absoluteString }
}

func extractAppIDRegex(from filename: String) -> String? {
    let pattern = #"^appmanifest_(\d+)\.acf$"#
    let regex = try? NSRegularExpression(pattern: pattern)
    let range = NSRange(filename.startIndex..<filename.endIndex, in: filename)
    guard let match = regex?.firstMatch(in: filename, options: [], range: range),
          match.numberOfRanges == 2,
          let idRange = Range(match.range(at: 1), in: filename) else { return nil }
    return String(filename[idRange])
}

func extractFolderNameRegex(_ path: String) -> String {
    let pattern = #"^file:\/\/\/Volumes\/(.+)\/steamapps\/$"#
    let regex = try? NSRegularExpression(pattern: pattern)
    let decodedpath = path.removingPercentEncoding ?? path
    let range = NSRange(decodedpath.startIndex..<decodedpath.endIndex, in: decodedpath)
    guard let match = regex?.firstMatch(in: decodedpath, options: [], range: range),
          match.numberOfRanges == 2,
          let idRange = Range(match.range(at: 1), in: decodedpath) else { return decodedpath }
    return String(decodedpath[idRange])
}

let id = extractAppIDRegex(from: "appmanifest_8870.acf") // "8870"

func scanSteamFolder(dest: URL) throws -> [String] {
    /**
     scans a folder and returns an array of steam games ids
     */
    try withSecurityScope(for: dest) {
        let f = FileManager.default
        let urls = try f.contentsOfDirectory(at: dest, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        return urls
            .filter { $0.pathExtension == "acf" }
            .map {
                extractAppIDRegex(from: $0.lastPathComponent)!
            }
    } ?? []
}

@MainActor
func updateSteamGamesList (games: [String], appIDS: inout [String]) -> Void {
    appIDS.append(contentsOf: games)
}

final class MountObserver {
    private var cancellables = Set<AnyCancellable>()

    init(onMount: @escaping () -> Void,
         onUnmount: @escaping () -> Void) {

        let center = NSWorkspace.shared.notificationCenter

        center.publisher(for: NSWorkspace.didMountNotification)
            .sink { _ in
                onMount()
            }
            .store(in: &cancellables)

        center.publisher(for: NSWorkspace.didUnmountNotification)
            .sink { _ in
                onUnmount()
            }
            .store(in: &cancellables)
    }
}

func getAllBottles(CXPatched: Bool = false) -> [URL] {
//    let DEFAULT_BOTTLE_PATH = "Library/Application Support/CrossOver/Bottles/"
    let f = FileManager.default
    let base = f.homeDirectoryForCurrentUser
    let bottlePath: URL = base
        .appendingPathComponent("Library", isDirectory: true)
        .appendingPathComponent("Application Support", isDirectory: true)
        .appendingPathComponent("CrossOver", isDirectory: true)
        .appendingPathComponent("Bottles", isDirectory: true)
    let bottlePathForCXP: URL = base.appendingPathComponent("CXPBottles", isDirectory: true)
    
    print(bottlePath)
    do {
        var subfolders: [URL] = try f.contentsOfDirectory(at: bottlePath, includingPropertiesForKeys: [.isDirectoryKey], options: [])
        if(CXPatched == true) {
            subfolders.append(contentsOf: try f.contentsOfDirectory(at: bottlePathForCXP, includingPropertiesForKeys: [.isDirectoryKey], options: []))
        }
        return subfolders.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        }
    } catch {
        print(error.localizedDescription)
    }
    return []
}

@discardableResult
func safeShell(_ command: String) throws -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    task.standardInput = nil

    try task.run()
    
//    let data = pipe.fileHandleForReading.readDataToEndOfFile()
//    let output = String(data: data, encoding: .utf8)!
//    print(output)
//    return output
    return "OK"
}

@discardableResult
func launchWindowsGame(id: String, cxAppPath: String, bottleName: String) throws -> String {
    print("attempting to run steam.exe on game id \(id)")
    return try safeShell("\(cxAppPath)/Contents/SharedSupport/CrossOver/bin/wine --bottle \(bottleName) \"C:\\Program Files (x86)\\Steam\\Steam.exe\" -nochatui -nofriendsui -silent -applaunch \(String(id))")
}
