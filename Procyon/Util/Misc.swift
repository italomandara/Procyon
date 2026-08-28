//
//  Util.swift
//  Procyon
//
//  Created by Italo Mandara on 03/02/2026.
//

import UniformTypeIdentifiers
import Combine
import AppKit

let AUTOFILL_CUSTOM_GAME_ENABLED: Bool = {
    let env = ProcessInfo.processInfo.environment["PROCYON_AUTOFILL_CUSTOM_GAME_ENABLED"]?.lowercased()
    switch env {
    case "1", "true", "yes":
        return true
    case "0", "false", "no":
        return false
    default:
        return false
    }
}()

let LIB_ROOT = "lib64"

let DEFAULT_BOTTLE_PATH = "Library/Application Support/CrossOver/Bottles/"
let BLACKLIST = [
    "228980", // Steamworks
]
let DEBUG_ENABLED: Bool = {
    let env = ProcessInfo.processInfo.environment["PROCYON_DEBUG"]?.lowercased()
    switch env {
    case "1", "true", "yes":
        return true
    case "0", "false", "no":
        return false
    default:
        return false
    }
}()
let useLogger: Bool = false

func prettyPrinted(dict: Dictionary<String, Any>) -> String {
    if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
       let str = String(data: data, encoding: .utf8) {
        return str
    }
    return "{}"
}

func addSteamFolderPaths(_ url: URL) {
    do {
        if (try getIDsFromFolder(dest: url).isEmpty) {
            console.warn("\(url) folder is empty")
            return
        }
    } catch {
        console.warn("Failed to validate steam folder \(url.path())")
        console.error(String(reflecting: error))
//        console.error(String(reflecting: error))
    }
    do {
        try persistFolderAccess(url: url)
    } catch {
        console.error("Failed to save steam folder")
        console.error(String(reflecting: error))
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

//let id = extractAppIDRegex(from: "appmanifest_8870.acf") // "8870"

func getIDsFromFolder(dest: URL) throws -> [String] {
    /**
     scans a folder and returns an array of steam games ids
     */
//    try withSecurityScope(for: dest) {
        let f = FileManager.default
        let urls = try f.contentsOfDirectory(at: dest, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants])
        return urls
        .filter { acfFileURL in
            acfFileURL.pathExtension == "acf"
        }
        .map { acfFileURL in
            extractAppIDRegex(from: acfFileURL.lastPathComponent) ?? "0"
        }
        .filter {
            gameID in !BLACKLIST.contains(gameID)
        }
//    } ?? []
}

func getIsNative(fromURL: URL) -> Bool {
    if !folderContainsFile(withExtension: "exe", at: fromURL) && folderContainsFile(withExtension: "app", at: fromURL) {
        return true
    }
    return false
}

func safeShell(_ command: String) throws {
    if(DEBUG_ENABLED) {
        let log = try safeShellWithOutput(command)
        console.log(log)
        return
    }
    let task = Process()
    
    task.standardInput = FileHandle.nullDevice
    task.standardOutput = FileHandle.nullDevice
    task.standardError = FileHandle.nullDevice
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")

    try task.run()
}

func safeShellWithOutput(_ command: String) throws -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardInput = nil
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")

    try task.run()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    return output
}

let DEFAULT_STEAM_MAC_PATH = "/Library/Application Support/Steam/"
let DEFAULT_STEAM_MAC_CONFIG_PATH = DEFAULT_STEAM_MAC_PATH + "config/"
let DEFAULT_STEAM_WINE_PATH = "/drive_c/Program Files (x86)/Steam/"
let DEFAULT_STEAM_WINE_CONFIG_PATH = DEFAULT_STEAM_WINE_PATH + "config/"

func getSteamUserID (usingURL: URL) -> String? {
    let steamLoginUsersPath = usingURL.appendingPathComponent("loginusers.vdf")
    guard let steamSettingsFile = try? String(contentsOfFile: steamLoginUsersPath.path(percentEncoded: false), encoding: .utf8) else { return nil }
    let parsed = parseVDFToDict(from: steamSettingsFile)
    let users = parsed["users"] as? [String: Any]
    return users?.keys.first?.description
}

func getSteamUserDataFallback (usingPath: URL) -> UserInfo? {
    let steamLoginUsersPath = usingPath.appendingPathComponent("loginusers.vdf")
    guard let steamSettingsFile = try? String(contentsOfFile: steamLoginUsersPath.path(percentEncoded: false), encoding: .utf8) else { return nil }
    let parsed = parseVDFToDict(from: steamSettingsFile)
    let users = parsed["users"] as? [String: Any]
    if let key = users?.keys.first {
        let user = users![key] as? [String: Any]
        let personaName = user?["PersonaName"] as? String ?? ""
        let avatar = usingPath
            .appendingPathComponent(DEFAULT_STEAM_WINE_CONFIG_PATH)
            .appendingPathComponent("avatarcache")
            .appendingPathComponent(key)
            .appendingPathExtension("png")
            .absoluteString
        let fallbackProfileData = UserInfo(
            steamID: "",
            communityVisibilityState: 0,
            profileState: 0,
            personaName: personaName,
            profileURL: "",
            avatar: avatar,
            avatarMedium: avatar,
            avatarFull: avatar,
            avatarHash: "",
            lastLogOff: 0,
            personaState: 0,
            primaryClanID: "",
            timeCreated: 0,
            personaStateFlags: 0,
            locCountryCode: nil,
            locStateCode: nil
        )
        return fallbackProfileData
    }
    return nil
}

func getSteamLibraryFolders(bottleURL: URL, from: URL) -> [URL] {
    let f = FileManager.default
    var steamLibraries: [URL] = []
    let drives = getBottleDrives(bottleURL: bottleURL)
    console.log("drives: \(String(describing: drives))")
    let steamSettingsPaths = [
        from.appendingPathComponent("libraryfolders.vdf"),
        f.homeDirectoryForCurrentUser
            .appendingPathComponent(DEFAULT_STEAM_MAC_CONFIG_PATH)
            .appendingPathComponent("libraryfolders.vdf")
    ].filter{ f.fileExists(atPath: $0.path(percentEncoded: false)) }
    for steamSettingsPath in steamSettingsPaths {
        do {
            let steamSettingsFile = try String(contentsOfFile: steamSettingsPath.path(percentEncoded: false), encoding: .utf8)
            let parsed = parseVDFToDict(from: steamSettingsFile)
            if let libraries = parsed["libraryfolders"] as? [String: Any] {
                for (_, value) in libraries { // Refactor this mess
                    if let val = (value as? [String: Any]) {
                        if let path = val["path"] as? String{
                            let driveAlias = String(path.split(separator: ":\\")[0]) + ":"
                            let splitPath = path.split(separator: ":")
                            if (splitPath.count > 1){
                                let partial = splitPath[1].replacingOccurrences(of: "\\\\", with: "/")
                                if let newPath = drives[driveAlias]?.appendingPathComponent(partial).appendingPathComponent("/steamapps") {
                                    steamLibraries.append(newPath)
                                } else {
                                    console.log("couldn't find Windows Steam config")
                                }
                            } else {
                                let macNewPath = URL(fileURLWithPath: path).appendingPathComponent("/steamapps")
                                steamLibraries.append(macNewPath)
                            }
                        }
                    }
                }
            }
        } catch {
            console.error(String(reflecting: error))
            return []
        }
    }
    console.log("all steam libraries \(steamLibraries.debugDescription)")
    return steamLibraries
}

func validateAddSteamFolder(_ url: URL, to folders: inout [String]) {
    if folders.contains(url.absoluteString) {
        console.log("\(url.absoluteString) folder exists!")
        return
    }
    addSteamFolderPaths(url)
    folders.append(url.absoluteString)
}

func mapPersonaState(_ state: Int) -> String {
    let states = ["Offline", "Online", "Busy", "Away", "Snooze", "looking to trade", "looking to play"]
    if (0..<states.count).contains(state){
        return states[state]
    }
    return "Unknown"
}

func getAppNames(isNative: Bool, gameURL: URL?) -> [String] {
    let ext = isNative ? "app" : "exe"
    let f = FileManager.default
    var results: [String] = []
    if(gameURL == nil) {
        return []
    }
    guard let enumerator = f.enumerator(at: gameURL!, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
        return []
    }
    for case let fileURL as URL in enumerator  {
        if(fileURL.pathExtension == ext) {
            results.append(fileURL.lastPathComponent)
        }
    }
    return results
}

class SteamLogWatcher {
    var steamID: String
    var steamPath: String
    var fileName: String
    var logPath: String {
        return "\(steamPath)/logs/\(fileName)"
    }
    
    init (steamID: String, steamPath: String, fileName: String) {
        self.steamID = steamID
        self.steamPath = steamPath
        self.fileName = fileName
    }
}

class SteamCloudSyncWatcher: SteamLogWatcher {
    init (steamID: String, steamPath: String) {
        super.init(steamID: steamID, steamPath: steamPath, fileName: "cloud_log.txt")
    }
    
    func waitForSteamCloudSync() async throws {
        let appIDMarker = "[AppID \(self.steamID)]"
        let successMSG = "Successfully synced"
        let deadline = Date().addingTimeInterval(60)
        var polling = true
        while polling {
            try await Task.sleep(nanoseconds: 100_000_000)
            let content = try String(contentsOfFile: logPath, encoding: .utf8)
            if(Date() > deadline) {
                console.log("\(self.steamID): Cloud sync timed out")
                polling = false
            }
            for fileContentLine in content.split(separator: "\n") {
                if(fileContentLine.contains(appIDMarker) && fileContentLine.contains(successMSG)) {
                    console.log("\(self.steamID): Cloud sync complete")
                    polling = false
                }
            }
        }
        return
    }
}

class SteamLaunchWatcher: SteamLogWatcher {
    init (steamID: String, steamPath: String) {
        super.init(steamID: steamID, steamPath: steamPath, fileName: "gameprocess_log.txt")
    }
    
    func getGameExe() async throws -> String {
        let appIDMarker = "AppID \(self.steamID) adding PID"
        var appExe = ""
        let deadline = Date().addingTimeInterval(90)
        var polling = true
        let pattern = /[^\\]+\.exe/
        while polling {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            do {
                let content = try String(contentsOfFile: logPath, encoding: .utf8)
                for fileContentLine in content.split(separator: "[") {
                    if(fileContentLine.contains(appIDMarker)) {
                        let match = fileContentLine.firstMatch(of: pattern)
                        appExe = String(match?.output ?? "not found")
                        polling = false
                    }
                }
                console.log("File \(self.fileName) found")
            } catch {
                console.error(String(describing: error))
                console.error("File \(self.fileName) seems missing, retrying...")
            }
            if(Date() > deadline) {
                console.log("\(self.steamID): App name fetching timed out")
                polling = false
            }
        }
        return appExe
    }
    
    func trackLaunch() async throws -> String {
        var polling = true
        var returnedValue = ""
        let appName = try await getGameExe()
        let deadline = Date().addingTimeInterval(90)
        console.log("App name found: \(appName)")
        while polling {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            if(Date() > deadline) {
                console.log("\(self.steamID): Launch tracking timed out")
                polling = false
            }
            let appNames = NSWorkspace.shared.runningApplications
                .flatMap{ app in [app.executableURL?.lastPathComponent ?? "none", app.bundleURL?.lastPathComponent ?? "none"] }
                .filter { lastpathcomponent in lastpathcomponent.contains(".exe")}
            if appNames.contains(appName) {
                returnedValue = appName
                polling = false
            }
        }
        return returnedValue
    }
}

func getGameTracker(appNames: [String], cxAppPath: String, bottleName: String, onLoad: @escaping (_ appName: String) -> Void, onTerminate: @escaping () -> Void, isNative: Bool, steamID: Int?, steamPath: String) async throws -> TerminationObserver {
    let tOb = TerminationObserver(then: { output in
        console.log(output.userInfo?.description ?? "no userInfo")
        let terminatedAppProcessName = output.userInfo?[AnyHashable("NSApplicationName")] as? String ?? "unknown"
        let terminatedAppPath = output.userInfo?[AnyHashable("NSApplicationPath")] as? String ?? "unknown"
        let terminatedAppName = String(terminatedAppPath.split(separator: "/").last ?? "unknown")
        if (appNames.contains(terminatedAppName) || appNames.contains(terminatedAppProcessName)) {
            console.log("\(appNames) -> \(terminatedAppName) or \(terminatedAppProcessName) has been terminated, closing steam...")
            Task {
                if(!isNative && steamID != nil){ // SteamCloudSyncWatcher isn't for native steam games
                    let cloudSyncWatcher = SteamCloudSyncWatcher(steamID: String(steamID!), steamPath: steamPath)
                    try await cloudSyncWatcher.waitForSteamCloudSync()
                }
                try await quitSteam(cxAppPath: cxAppPath, bottleName: bottleName, isNative: isNative)
                try await closeWineActivities()
                onTerminate()
                console.log("onTerminate() was called")
            }
        }
    })
    if let steamID = steamID {
        do {
            let appName = try await SteamLaunchWatcher(steamID: String(steamID), steamPath: steamPath).trackLaunch()
            if appName != "" {
                console.log("found game \(appName), loading...")
                onLoad(appName)
            }
        } catch {
            console.log("\(appNames.joined(separator: ", ")), timeout...")
            onTerminate()
        }
    }
    return tOb
}

//func getGameTracker(appNames: [String], cxAppPath: String, bottleName: String, onLoad: @escaping (_ game: String) -> Void, onTerminate: @escaping () -> Void, isNative: Bool, steamID: Int, steamPath: String) async throws -> TerminationObserver {
//    let tOb = TerminationObserver(then: { output in
//        console.log(output.userInfo?.description ?? "no userInfo")
//        let terminatedAppProcessName = output.userInfo?[AnyHashable("NSApplicationName")] as? String ?? "unknown"
//        let terminatedAppPath = output.userInfo?[AnyHashable("NSApplicationPath")] as? String ?? "unknown"
//        let terminatedAppName = String(terminatedAppPath.split(separator: "/").last ?? "unknown")
//        if (appNames.contains(terminatedAppName) || appNames.contains(terminatedAppProcessName)) {
//            console.log("\(appNames) -> \(terminatedAppName) or \(terminatedAppProcessName) has been terminated, closing steam...")
//            Task {
//                if(!isNative){
//                    let cloudSyncWatcher = SteamCloudSyncWatcher(steamID: String(steamID), steamPath: steamPath)
//                    try await cloudSyncWatcher.waitForSteamCloudSync()
//                }
//                try await quitSteam(cxAppPath: cxAppPath, bottleName: bottleName, isNative: isNative)
//                try await closeWineActivities()
//                onTerminate()
//                console.log("onTerminate() was called")
//            }
//        }
//    })
//    do {
//        let appName = try await SteamLaunchWatcher(steamID: String(steamID), steamPath: steamPath).trackLaunch()
//        console.log("found game \(appName), loading...")
//        onLoad(appName)
//    } catch {
//        console.log("\(appNames.joined(separator: ", ")), timeout...")
//        onTerminate()
//    }
//    return tOb
//}

func isSameFile(_ file1URL: URL, _ file2URL: URL) -> Bool {
    let f = FileManager.default
    do {
        let attrs1 = try f.attributesOfItem(atPath: file1URL.path())
        let attrs2 = try f.attributesOfItem(atPath: file2URL.path())
        let sameSize = attrs1[.size] as? Int == attrs2[.size] as? Int
        let sameDate = attrs1[.modificationDate] as? Date == attrs2[.modificationDate] as? Date
        if(sameSize && sameDate) {
            // just comparing attributes for now
            return true
        }
    } catch {
        console.error("couldn't get file attributes")
        console.error(String(reflecting: error))
        return false
    }
    return false
}

func getSystemWOW64URL(from: URL) -> URL {
    return from
        .appending(path: "drive_c")
        .appending(path: "windows")
        .appending(path: "syswow64")
}

func getSystem32URL(from: URL) -> URL {
    return from
        .appending(path: "drive_c")
        .appending(path: "windows")
        .appending(path: "system32")
}

func cpyd8d9DLLs(to url: URL, enable: Bool = true) throws -> Void {
    let f = FileManager.default
    let files = ["d3d9.dll", "d3d8.dll"]
    
    func copyByBitness(dllsUrl: URL, file: String, is32Bit: Bool) throws {
        let dllPathComponentByBitness = "drive_c" + (is32Bit ? "/windows/SysWOW64": "/windows/System32")
        let dllPath = dllsUrl.appendingPathComponent(file)
        let dllDest = url.appendingPathComponent(dllPathComponentByBitness).appendingPathComponent(file) // the logic seems flipped but it's actually how the winwos logic works System32 is for 64 bits libs
        console.log("\(file) exists")
        if(enable) {
            if(!isSameFile(dllPath, dllDest)){
                if(!f.fileExists(atPath: dllDest.appendingPathExtension("old").path())){
                    try? f.moveItem(at: dllDest, to: dllDest.appendingPathExtension("old"))
                } else {
                    try? f.removeItem(at: dllDest)
                }
                try f.copyItem(at: dllPath, to: dllDest)
            } else {
                console.log("already patched with the latest dx9 skipping copy")
            }
        } else {
            if(!f.fileExists(atPath: dllDest.path())){
                try? f.removeItem(at: dllDest)
            }
            try f.copyItem(at: dllDest.appendingPathExtension("old"), to: dllDest)
        }
        
    }
    
    for file in files {
        if let dllsUrl = Bundle.main.url(forResource: "d9vk/x32", withExtension: nil) {
            try copyByBitness(dllsUrl: dllsUrl, file: file, is32Bit: true)
        } else {
            console.log("Couldn't find \(file)")
        }
        if let dllsUrl = Bundle.main.url(forResource: "d9vk/x64", withExtension: nil) {
            try copyByBitness(dllsUrl: dllsUrl, file: file, is32Bit: false)
        } else {
            console.log("Couldn't find \(file)")
        }
    }
}

class TarDownloader: NSObject, URLSessionDownloadDelegate {
    /**
     Class that takes 3 mandatory arguments
     fromUrl: the http url from where we download
     onProgress: (Double) called as the download progresses progress is passed to the function
     onComplete: (URL) called when download + extraction is complete the URL
     onError: (Error) called at any point there's an error
     */
    var fromUrl: URL
    var downloadDir: URL
    var onProgress: (Double) -> Void
    var onComplete: (URL) -> Void
    var onError: (Error) -> Void
    
    init(fromUrl: URL, onProgress: @escaping (Double) -> Void, onComplete: @escaping (URL) -> Void, onError: @escaping (Error) -> Void) {
        self.downloadDir = TarDownloader.getDownloadsDir()
        self.fromUrl = fromUrl
        self.onProgress = onProgress
        self.onError = onError
        self.onComplete = onComplete
        super.init()
    }
    
    public static func getDownloadsDir() -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDir.appendingPathComponent("\(appName)/downloads")
    }
    
    public static func deleteAllDownloadCache() {
        let downloadDir = TarDownloader.getDownloadsDir()
        try? FileManager.default.removeItem(at: downloadDir)
        deleteUsrDefOptionStartsWith(prefix: "downloads")
    }
    
    func download() {
        let f = FileManager.default
        console.log(self.fromUrl.debugDescription)
        if let lastDownloadedPath = readUsrDefOptionString(key: namespacedKey("downloads", self.fromUrl.lastPathComponent)){
            if lastDownloadedPath == self.fromUrl.path(percentEncoded: false) {
                console.log("download cache found, skipping download")
                return self.onComplete(self.downloadDir)
            }
        }
        try? f.createDirectory(at: downloadDir, withIntermediateDirectories: true, attributes: nil)
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        session.downloadTask(with: fromUrl).resume()
    }
    
    private func extract() -> Process {
        let filename = fromUrl.lastPathComponent
        let dest = downloadDir.appendingPathComponent(filename) // assuming the file has the correct extension
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xf", dest.path, "-C", downloadDir.path] // just xf autodetects the compression format
        return process
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
        DispatchQueue.main.async {
            self.onProgress(progress) // percentage
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let f = FileManager.default
        let destination = downloadDir.appendingPathComponent(fromUrl.lastPathComponent)
        
        do {
            if f.fileExists(atPath: destination.path) {
                try f.removeItem(at: destination)
            }
            try f.moveItem(at: location, to: destination)
            let process = extract()
            process.terminationHandler = { process in
                DispatchQueue.main.async {
                    if process.terminationStatus == 0 {
                        self.onComplete(self.downloadDir)
                        persistUsrDefOptionString(key: namespacedKey("downloads", self.fromUrl.lastPathComponent), value: self.fromUrl.path(percentEncoded: false))
                    } else {
                        let error = NSError(domain: "TarDownloader", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "tar extraction failed"])
                        self.onError(error)
                    }
                }
            }
            try? process.run()
        } catch {
            DispatchQueue.main.async { self.onError(error) }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            DispatchQueue.main.async { self.onError(error) }
        }
    }
    
    func clearTemp() {
        try? FileManager.default.removeItem(at: downloadDir )
    }
}
