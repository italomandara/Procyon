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

let blacklist: [String] = ["228980"]

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

func namespacedKey(_ namespace: String, _ key: String) -> String {
    "\(namespace).\(key)"
}

func persistUsrDefData(key: String, data: Codable) {
    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(data) else { return }
    let groupDefaults = UserDefaults(suiteName: "group.com.italomandara.procyon")!
    groupDefaults.set(data, forKey: key)
}

func readUsrDefData<T: Decodable>(key: String, type: T.Type = T.self) -> T? {
    let groupDefaults = UserDefaults(suiteName: "group.com.italomandara.procyon")!
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
        if (try getIDsFromFolder(dest: url).isEmpty) {
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

func getIDsFromFolder(dest: URL) throws -> [String] {
    /**
     scans a folder and returns an array of steam games ids
     */
    try withSecurityScope(for: dest) {
        let f = FileManager.default
        let urls = try f.contentsOfDirectory(at: dest, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants])
        return urls
            .filter { $0.pathExtension == "acf" }
            .map {
                extractAppIDRegex(from: $0.lastPathComponent)!
            }
            .filter { !blacklist.contains($0) }
    } ?? []
}

func folderContainsFile(withExtension ext: String, at url: URL) -> Bool {
    let f = FileManager.default
    let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey]
    let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]

    guard let enumerator = f.enumerator(at: url, includingPropertiesForKeys: keys, options: options) else {
        return false
    }

    for case let fileURL as URL in enumerator {
        // Quick check via path extension
        if fileURL.pathExtension.caseInsensitiveCompare(ext) == .orderedSame {
            return true
        }
    }
    return false
}

func getIsNative(fromURL: URL) -> Bool {
    if folderContainsFile(withExtension: "exe", at: fromURL) {
        return false
    }
    return true
}

func getGamesMeta(from: URL) throws -> [GamesMeta] {
    /**
     scans a folder and returns an array of steam games meta
     */
    var array: [GamesMeta] = []
    try withSecurityScope(for: from) {
        let f = FileManager.default
        let urls = try f.contentsOfDirectory(at: from, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]).filter { $0.pathExtension == "acf" }
        try urls.forEach { url in
            let file  = try readFile(at: url)
            let parsed = parseACFToDict(from: file)
            let meta = mapDictToGamesMeta(from: parsed)
            meta.gameURL = from.appendingPathComponent("common").appendingPathComponent(meta.installdir)
            meta.isNative = getIsNative(fromURL: meta.gameURL!)
            array.append(meta)
        }
    }
    return array
}

func readFile(at: URL) throws -> String {
    return try String(contentsOf: at, encoding: String.Encoding.utf8)
}

func parseACFToDict(from: String) -> [String:String] {
    /**
     Incomplete shallow parser that the skips main property
     parses an ACF file content String into a dictionary
     */
    var dictionary: [String:String] = [:]
    let search1: Regex = /(("\w+")\n\{\n(.*\n)+\})+/
    let search2: Regex = /(\t"(\w+?)"\t+"(.*?)")\n(?=\t"\w+")/
    
    let matches = from.matches(of: search1)
    for match in matches {
        let values = match.0.matches(of: search2)
        for value in values {
            dictionary[value.2.description] = value.3.description
        }
    }
    return dictionary
}

func mapDictToGamesMeta(from: [String:String]) -> GamesMeta {
    /**
     Incomplete it only maps appid and installdir
     */
    return GamesMeta(appid: from["appid"] ?? "unknown", installdir: from["installdir"] ?? "unknown")
}

func mapGamesACFMeta (from: URL) -> [SteamACFMeta] {
    return []
}

//@MainActor
//func updateSteamGamesList (games: [String], appIDS: inout [String]) -> Void {
//    appIDS.append(contentsOf: games)
//}

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

struct GameOptionsData: Codable {
    var cxGraphicsBackend: String
    var wineMSync: Bool
    var mtlHudEnabled: Bool
    var gameArguments: String
    var dxmtPreferredMaxFrameRate: Double
    var dxmtMetalFXSpatial: Bool
    var dxmtMetalSpatialUpscaleFactor: Double
    var advertiseAVX: Bool
    var envVariables: String
    
    init(data: GameOptions) {
        self.cxGraphicsBackend = data.cxGraphicsBackend
        self.wineMSync = data.wineMSync
        self.mtlHudEnabled = data.mtlHudEnabled
        self.gameArguments = data.gameArguments
        self.dxmtPreferredMaxFrameRate = data.dxmtPreferredMaxFrameRate
        self.dxmtMetalFXSpatial = data.dxmtMetalFXSpatial
        self.dxmtMetalSpatialUpscaleFactor = data.dxmtMetalSpatialUpscaleFactor
        self.advertiseAVX = data.advertiseAVX
        self.envVariables = data.envVariables
    }
}

class GameOptions: ObservableObject {
    @Published var cxGraphicsBackend: String
    @Published var wineMSync: Bool
    @Published var mtlHudEnabled: Bool
    @Published var dxvk: String?
    @Published var wineEsync: String?
    @Published var d3dMEnableMetalFX: String?
    @Published var d3dSupportDXR: String?
    @Published var gameArguments: String
    @Published var dxmtPreferredMaxFrameRate: Double
    @Published var dxmtMetalFXSpatial: Bool
    @Published var dxmtMetalSpatialUpscaleFactor: Double
    @Published var advertiseAVX: Bool
    @Published var envVariables: String
    
    init(cxGraphicsBackend: String = "d3dmetal", wineMSync: Bool = true, mtlHudEnabled: Bool = true, dxvk: String? = nil, wineEsync: String? = nil, d3dMEnableMetalFX: String? = nil, d3dSupportDXR: String? = nil, gameArguments: String = "", dxmtPreferredMaxFrameRate: Double = 0, dxmtMetalFXSpatial: Bool = false, dxmtMetalSpatialUpscaleFactor: Double = 1.0, advertiseAVX: Bool = true, envVariables: String = "") {
        self.cxGraphicsBackend = cxGraphicsBackend
        self.wineMSync = wineMSync
        self.mtlHudEnabled = mtlHudEnabled
        self.dxvk = dxvk
        self.wineEsync = wineEsync
        self.d3dMEnableMetalFX = d3dMEnableMetalFX
        self.d3dSupportDXR = d3dSupportDXR
        self.gameArguments = gameArguments
        self.dxmtMetalFXSpatial = dxmtMetalFXSpatial
        self.dxmtMetalSpatialUpscaleFactor = dxmtMetalSpatialUpscaleFactor
        self.dxmtPreferredMaxFrameRate = dxmtPreferredMaxFrameRate
        self.advertiseAVX = advertiseAVX
        self.envVariables = envVariables
    }
    func set(data: GameOptionsData) {
        self.cxGraphicsBackend = data.cxGraphicsBackend
        self.wineMSync = data.wineMSync
        self.mtlHudEnabled = data.mtlHudEnabled
        self.gameArguments = data.gameArguments
        self.dxmtMetalFXSpatial = data.dxmtMetalFXSpatial
        self.dxmtMetalSpatialUpscaleFactor = data.dxmtMetalSpatialUpscaleFactor
        self.dxmtPreferredMaxFrameRate = data.dxmtPreferredMaxFrameRate
        self.advertiseAVX = data.advertiseAVX
        self.envVariables = data.envVariables
    }
}

func getInlineEnvs(from: GameOptions) -> String {
    func onOff(_ value: Bool?) -> String {
        return value != nil && value == true ? "1" : "0"
    }
    var value = "\(from.envVariables) "
    let defaults = "WINEDEBUG=-all "
    func getDxmtConfigEnv(values: String) -> String {
        return "DXMT_CONFIG=\"\(values)\""
    }
    func DoubleToFormattedStr(_ value: Double, _ digits: Int = 2) -> String {
        return String(value.formatted(.number.precision(.fractionLength(0...digits))))
    }
    value += defaults
    let mtlHudEnabled = "MTL_HUD_ENABLED=\(onOff(from.mtlHudEnabled)) "
    value += mtlHudEnabled
    let advertiseAVX = "ROSETTA_ADVERTISE_AVX=\(onOff(from.advertiseAVX)) "
    value += advertiseAVX
    let dxmtMetalFXSpatial = "DXMT_METALFX_SPATIAL_SWAPCHAIN=\(onOff(from.dxmtMetalFXSpatial)) "
    value += dxmtMetalFXSpatial
    
    let dxmtPreferredMaxFrameRate = from.dxmtPreferredMaxFrameRate > 20 ? "d3d11.preferredMaxFrameRate=\(DoubleToFormattedStr(from.dxmtPreferredMaxFrameRate));" : ""
    let dxmtMetalSpatialUpscaleFactor = from.dxmtMetalFXSpatial == true ? "d3d11.metalSpatialUpscaleFactor=\(from.dxmtMetalSpatialUpscaleFactor);" : ""
    value += getDxmtConfigEnv(values:  dxmtMetalSpatialUpscaleFactor + dxmtPreferredMaxFrameRate)
    return value
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
    let arguments = options != nil ? " " + options!.gameArguments : ""
    let command = "\(getInlineEnvs(from: options!)) \(cxAppPath)/Contents/SharedSupport/CrossOver/bin/wine --bottle \(bottleName) \"C:\\Program Files (x86)\\Steam\\Steam.exe\" -nochatui -nofriendsui -silent -applaunch \(String(id))" + arguments
    console.warn(command)
    try safeShell(command)
}

func launchNativeGame(id: String, cxAppPath: String, selectedBottle: String, options: GameOptions? = nil) async throws {
    let arguments = options != nil ? " " + options!.gameArguments : ""
    let command = "\(getInlineEnvs(from: options!)) /Applications/Steam.app/Contents/MacOS/steam_osx -nochatui -nofriendsui -silent -applaunch \(String(id))" + arguments
    console.warn(command)
    try safeShell(command)
}

func installGame(id: String) {
//    https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip
//    steamcmd +login YOUR_USERNAME +app_update 1489410 validate +quit
//    steamcmd +login USER +force_install_dir "C:\Program Files (x86)\Steam\steamapps\common\MyGame" +app_update 1489410 validate +quit
}

let logger = Logger(subsystem: "CXPatcher", category: "util")

class Console {
    var logMessages: [String] = []
    var enableLogFile: Bool = false
    let f = FileManager.default
    
    func log(_ msg: String) {
        print(msg)
        if enableLogFile == true {
            logMessages.append(msg)
        }
    }
    func warn(_ msg: String) {
        print(msg)
        logger.notice("\(msg)")
        if enableLogFile == true {
            logMessages.append(msg)
        }
    }
    func error(_ msg: String) {
        let errorMsg: String = "ERROR: \(msg)"
        logger.error("\(errorMsg)")
        console.warn(errorMsg)
        if enableLogFile == true {
            logMessages.append(msg)
        }
    }
    func clear() {
        self.logMessages.removeAll()
    }
    func saveLogs(to: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Procyon.log.txt")) {
        if f.fileExists(atPath: to.path()) {
            do {
                try f.removeItem(at: to)
            } catch {
                console.error(error.localizedDescription)
            }
        }
        let content = logMessages.joined(separator: "\n")
        console.warn("Saving logs to \(to)")
        do {
            try content.write(to: to, atomically: true, encoding: .utf8)
        } catch {
            console.error(error.localizedDescription)
        }
    }
}

let console = Console()

func localizedString(forKey: String, value: String? = nil) -> String {
    return "\(forKey) \(value ?? "")"
}

func showFolder(url: URL) {
    let targetURL: URL = url
print(url)
    NSWorkspace.shared.open(targetURL)
}
