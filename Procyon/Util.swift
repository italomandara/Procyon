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
import os

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
            console.warn("Folder is empty")
            return
        }
    } catch {
        console.warn("Failed to validate steam folder")
        console.error(error.localizedDescription)
    }
    do {
        try persistFolderAccess(url: url)
    } catch {
        console.warn("Failed to save steam folder")
        console.error(error.localizedDescription)
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
    
    console.warn(bottlePath.absoluteString)
    do {
        var subfolders: [URL] = try f.contentsOfDirectory(at: bottlePath, includingPropertiesForKeys: [.isDirectoryKey], options: [])
        if(CXPatched == true) {
            do {
                subfolders.append(contentsOf: try f.contentsOfDirectory(at: bottlePathForCXP, includingPropertiesForKeys: [.isDirectoryKey], options: []))
            } catch {
                console.warn(error.localizedDescription)
                console.warn("couldn't find the CXPatched bottles")
            }
        }
        console.warn("subfolders \(subfolders.debugDescription)")
        let filtered = subfolders.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        }
        console.warn("filtered: \(filtered.debugDescription)")
        return filtered
    } catch {
        console.warn(error.localizedDescription)
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
//    console.warn(output)
//    return output
    return "OK"
}

func modifyBottleSettingOptions(selectedBottle: String, options: [String: String]) {
    options.forEach { option in
        console.warn("key: \(option.key), value: \(option.value)")
    }
}

func closeWineActivities(cxAppPath: String, bottleName: String) async throws {
    // Wait for graceful termination, then escalate to forceTerminate, then give a final wait
    let gracePeriod: UInt64 = 2_000_000_000 // 2 seconds in nanoseconds
    let pollInterval: UInt64 = 200_000_000  // 0.2 seconds in nanoseconds
//    let forceTimeout: UInt64 = 6_000_000_000 // ~6 seconds total before force
    let absoluteTimeout: UInt64 = 12_000_000_000 // ~12 seconds absolute timeout

    
    // Capture the target apps first to avoid the list changing while iterating
    let targets = NSWorkspace.shared.runningApplications.filter { app in
        guard let url = app.executableURL else { return false }
        return url.lastPathComponent.lowercased().hasSuffix(".exe")
    }

    // Send terminate to all matching apps
    for app in targets {
        if let name = app.executableURL?.lastPathComponent {
            console.warn("terminating \(name)")
        }
        app.terminate()
    }

    // Helper to check if all targets have terminated
    func allTerminated(_ apps: [NSRunningApplication]) -> Bool {
        apps.allSatisfy { $0.isTerminated }
    }

    var elapsed: UInt64 = 0
    // First grace period loop
    while !allTerminated(targets) && elapsed < gracePeriod {
        try await Task.sleep(nanoseconds: pollInterval)
        elapsed += pollInterval
    }

    // If still not all terminated after grace period, escalate with terminate
    if !allTerminated(targets) {
        for app in targets where !app.isTerminated {
            console.warn("force terminating \(app.executableURL?.lastPathComponent ?? "<unknown>")")
            app.forceTerminate()
        }
    }

    // Final wait until absolute timeout or done
    while !allTerminated(targets) && elapsed < absoluteTimeout {
        try await Task.sleep(nanoseconds: pollInterval)
        elapsed += pollInterval
    }
}

func quitSteam(cxAppPath: String, bottleName: String) async throws {
    let absoluteTimeout: UInt64 = 2_000_000_000
    let pollInterval: UInt64 = 200_000_000
    var elapsed: UInt64 = 0
    let targets = NSWorkspace.shared.runningApplications.filter { app in
        guard let url = app.executableURL else { return false }
        return url.lastPathComponent.lowercased().hasSuffix(".exe")
    }
    func allTerminated(_ apps: [NSRunningApplication]) -> Bool {
        apps.allSatisfy { $0.isTerminated }
    }
    try safeShell("\(cxAppPath)/Contents/SharedSupport/CrossOver/bin/wine --bottle \(bottleName) \"C:\\Program Files (x86)\\Steam\\Steam.exe\" -shutdown")
    try await Task.sleep(nanoseconds: 2_000_000_000)
    try safeShell("\(cxAppPath)/Contents/SharedSupport/CrossOver/bin/wine --bottle \(bottleName) wineserver -k")
    while !allTerminated(targets) && elapsed < absoluteTimeout {
        try await Task.sleep(nanoseconds: pollInterval)
        elapsed += pollInterval
    }
}

func toCrossoverENVString(_ key: String, _ value: String) -> String {
    return "\"\(key)\"=\"\(value)\""
}

func getCXBottleConfigFileURL(selectedBottle: String) -> URL? {
    return URL(string: selectedBottle)?.appendingPathComponent("cxbottle.conf")
}

func editCXBottleConfigFile(selectedBottle: String, options: [String: String]) throws {
    let bottleURL = getCXBottleConfigFileURL(selectedBottle: selectedBottle)
    let original = try String(contentsOf: bottleURL!, encoding: .utf8)
    let lines = original.components(separatedBy: .newlines)
    let newLines = lines.map { line in
        for (key, value) in options {
            if(line.hasPrefix("\"\(key)\"")) {
                return toCrossoverENVString(key, value)
            }
        }
        return line
    }
    let updated = newLines.joined(separator: "\n")
    try updated.write(to: bottleURL!, atomically: true, encoding: .utf8)
}

enum CXGraphicsBackend: String {
    case dxmt = "dxmt"
    case d3dmetal = "d3dmetal"
    case wine = "wine"
    case dxvk = "dxvk"
}

enum OnOff: String {
    case off = "0"
    case on = "1"
}

class GameOptions: ObservableObject {
    @Published var cxGraphicsBackend: String = "d3dmetal"
    @Published var wineMSync: Bool = true
    @Published var mtlHudEnabled: Bool = true
    @Published var dxvk: String?
    @Published var wineEsync: String?
    @Published var d3dMEnableMetalFX: String?
    @Published var d3dSupportDXR: String?
    @Published var gameArguments: String = ""
}

func launchWindowsGame(id: String, cxAppPath: String, selectedBottle: String, options: GameOptions? = nil) async throws {
    if(options != nil){
        let optionsDictionary = [
            "CX_GRAPHICS_BACKEND": options!.cxGraphicsBackend,
            "WINEMSYNC": options!.wineMSync ? "1" : "0",
            "MTL_HUD_ENABLED": options!.mtlHudEnabled ? "1" : "0"
        ]
        console.warn("applying config changes to the bottle \(selectedBottle)...")
        try editCXBottleConfigFile(selectedBottle: selectedBottle, options: optionsDictionary)
    }
    let bottleName = URL(string: selectedBottle)?.lastPathComponent ?? ""
    console.warn("restarting bottle...")
    try await closeWineActivities(cxAppPath: cxAppPath, bottleName: bottleName)
//    try await quitSteam(cxAppPath: cxAppPath, bottleName: bottleName)

    console.warn("attempting to run steam.exe on game id \(id)")
    let mtlHudEnabled = options != nil && options!.mtlHudEnabled ? "1" : "0"
    let arguments = options != nil ? " " + options!.gameArguments : ""
    try safeShell("MTL_HUD_ENABLED=\(mtlHudEnabled) \(cxAppPath)/Contents/SharedSupport/CrossOver/bin/wine --bottle \(bottleName) \"C:\\Program Files (x86)\\Steam\\Steam.exe\" -nochatui -nofriendsui -silent -applaunch \(String(id))" + arguments)
}

func installGame(id: String) {
//    https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip
//    steamcmd +login YOUR_USERNAME +app_update 1489410 validate +quit
//    steamcmd +login USER +force_install_dir "C:\Program Files (x86)\Steam\steamapps\common\MyGame" +app_update 1489410 validate +quit
}

let logger = Logger(subsystem: "CXPatcher", category: "util")

class Console {
    var logMessages: [String] = []
    let f = FileManager.default
    
    func log(_ msg: String) {
        console.warn(msg)
//        logMessages.append(msg)
    }
    func warn(_ msg: String) {
        print(msg)
//        logMessages.append(msg)
        logger.notice("\(msg)")
    }
    func error(_ msg: String) {
        let errorMsg: String = "ERROR: \(msg)"
        logger.error("\(errorMsg)")
        console.warn(errorMsg)
//        logMessages.append(errorMsg)
    }
    func clear() {
        self.logMessages.removeAll()
    }
//    func saveLogs(to: URL) {
//        if f.fileExists(atPath: to.path()) {
//            do {
//                try f.removeItem(at: to)
//            } catch {
//                console.error(error.localizedDescription)
//            }
//        }
//        let content = logMessages.joined(separator: "\n")
//        console.warn("Saving logs to \(to)")
//        do {
//            try content.write(to: to, atomically: true, encoding: .utf8)
//        } catch {
//            console.error(error.localizedDescription)
//        }
//    }
}

let console = Console()
