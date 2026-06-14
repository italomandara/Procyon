//
//  Launcher.swift
//  Procyon
//
//  Created by Italo Mandara on 24/02/2026.
//

import AppKit

func closeWineActivities() async throws {
    // Wait for graceful termination, then escalate to forceTerminate, then give a final wait
    let gracePeriod: UInt64 = 2_000_000_000 // 2 seconds in nanoseconds
    let pollInterval: UInt64 = 200_000_000  // 0.2 seconds in nanoseconds
//    let forceTimeout: UInt64 = 6_000_000_000 // ~6 seconds total before force
    let absoluteTimeout: UInt64 = 12_000_000_000 // ~12 seconds absolute timeout

    
    // Capture the target apps first to avoid the list changing while iterating
    let targets = NSWorkspace.shared.runningApplications.filter { app in
        guard let url = app.executableURL else { return false }
        return url.lastPathComponent.lowercased().hasSuffix(".exe") || url.lastPathComponent.lowercased().contains("wine")
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

func trackPlaying(apps: [String], then: @escaping () -> Void, onTimeout: @escaping () -> Void, isNative: Bool) async throws -> Void {
    let pollInterval: UInt64 = 500_000_000
    let gracePeriod: UInt64 = 60_000_000_000 // after 60 seconds give up tracking
    var elapsed: UInt64 = 0
    var targets = isNative ? NSWorkspace.shared.runningApplications : NSWorkspace.shared.runningApplications.filter { app in
        guard let url = app.executableURL else { return false }
        return url.lastPathComponent.lowercased().hasSuffix(".exe")
    }
    
    var nativeOrWineApps: [String] {
        isNative ? apps + apps.map { $0.replacingOccurrences(of: ".app", with: "") } : apps
    }
    
    while (elapsed < gracePeriod) {
        try await Task.sleep(nanoseconds: pollInterval)
        let newTargets = isNative ? NSWorkspace.shared.runningApplications : NSWorkspace.shared.runningApplications.filter { app in
            guard let url = app.executableURL else { return false }
            return
                url.lastPathComponent.lowercased().hasSuffix(".exe") &&
                !targets.contains(where: { $0.processIdentifier == app.processIdentifier }) &&
                url.lastPathComponent.lowercased().contains("wineloader")
        }
        targets.append(contentsOf: newTargets)
        if(newTargets.contains { Set(nativeOrWineApps).contains($0.executableURL?.lastPathComponent) }) {
            if(!isNative) { // attempts to "select" the app if for some reason it isn't (happens with wine/crossover)
                newTargets.first(where: { Set(nativeOrWineApps).contains($0.executableURL?.lastPathComponent) })!.activate(options: [.activateAllWindows])
            }
            then()
            return
        }
        elapsed += pollInterval
    }
    if(elapsed < gracePeriod){
        console.warn("\(nativeOrWineApps.description) crashed")
    } else {
        console.warn("couldn't find apps \(nativeOrWineApps.description) within the allowed grace period elapsed: \(elapsed/1_000_000_000)s ")
    }
    console.log("starting timeout callback...")
    onTimeout()
}

func quitSteam(cxAppPath: String, bottleName: String, isNative: Bool) async throws -> Void {
    console.log("quitting steam...")
    if(isNative) {
        let steamBundleID = "com.valvesoftware.steam"
        if let steamApp = NSRunningApplication.runningApplications(withBundleIdentifier: steamBundleID).first {
            steamApp.terminate() // polite request to quit
        }
    } else {
        try safeShell("\(cxAppPath)/Contents/SharedSupport/CrossOver/bin/wine --bottle \(bottleName) \"C:\\Program Files (x86)\\Steam\\Steam.exe\" -shutdown")
    }
}

func quitWine(cxAppPath: String, bottleName: String) async throws -> Void {
    console.log("quitting wine...")
    try safeShell("\(cxAppPath)/Contents/SharedSupport/CrossOver/bin/wine --bottle \(bottleName) wineserver -k")
}

func normalizeSteamPath(path: String) -> String {
    var normalizedPath = path + "/steam.exe"
    if normalizedPath.lowercased().hasPrefix("drive_c/") {
        let remainder = normalizedPath.dropFirst("drive_c/".count)
        normalizedPath = "C:/" + remainder
    }
    return normalizedPath.replacingOccurrences(of: "/", with: "\\")
}

func openSteam(cxAppPath: String?, selectedBottle: String?, steamWinePath: String) {
    if cxAppPath == nil || selectedBottle == nil {
        console.error(String(reflecting: "CXAppPath or selectedBottle is nil"))
        return
    }
    console.log("Launching Steam with \(cxAppPath!) \(selectedBottle!) \(steamWinePath) ...")
    if let bottleName = URL(string: selectedBottle!)?.lastPathComponent {
        let normalizedPath = normalizeSteamPath(path: steamWinePath)
        let wineSteamPathArg = "\"" + normalizedPath.replacingOccurrences(of: "/", with: "\\") + "\""
        let steamLaunchCommand = "MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS=0 CX_GRAPHICS_BACKEND=\"\(CXGraphicsBackend.d3dmetal.rawValue)\" \(cxAppPath!)/Contents/SharedSupport/CrossOver/bin/wine --bottle \(bottleName) \(wineSteamPathArg)"
        do {
            try safeShell(steamLaunchCommand)
            console.log(steamLaunchCommand)
        } catch {
            console.error(String(reflecting: error))
        }
    }
}

func copyMoltenVK(cxAppPath: String, vulkanLibID: String) throws -> Void {
    let cxURL = URL(fileURLWithPath: cxAppPath)
    let moltenVKDest = cxURL.appendingPathComponent(SHARED_SUPPORT_COMPONENT + "/lib64/libMoltenVK.dylib")
    console.log(moltenVKDest.path())
    switch (vulkanLibID) {
    case "latest":
        console.log(Bundle.main.url(forResource: "libMoltenVK-latest", withExtension: "dylib")?.path() ?? "")
        try copyResource(name: "libMoltenVK-latest.dylib", destUrl: moltenVKDest)
    case "experimental":
        console.log(Bundle.main.url(forResource: "libMoltenVK-experimental", withExtension: "dylib")?.path() ?? "")
        try copyResource(name: "libMoltenVK-experimental.dylib", destUrl: moltenVKDest)
    case "experimental2":
        console.log(Bundle.main.url(forResource: "libMoltenVK-experimental2", withExtension: "dylib")?.path() ?? "")
        try copyResource(name: "libMoltenVK-experimental2.dylib", destUrl: moltenVKDest)
    case "experimental3":
        console.log(Bundle.main.url(forResource: "libMoltenVK-experimental3", withExtension: "dylib")?.path() ?? "")
        try copyResource(name: "libMoltenVK-experimental3.dylib", destUrl: moltenVKDest)
//    case "kosmickrisp":
//        if let url = Bundle.main.url(forResource: "libvulkan_kosmickrisp", withExtension: "dylib") {
//             try copyResource(name: "libMoltenVK-experimental2.dylib", destUrl: cxURL)
//        }
    default:
        try restoreOrig(destUrl: moltenVKDest)
    }
}

func launchWindowsGame(id: String, cxAppPath: String, selectedBottle: String, options: GameOptions? = nil, appExeURL: URL? = nil, steamWinePath: String) async throws -> Void {
    console.log("options: \(options.debugDescription)")
    if let vulkanLibID = options?.vulkanLib {
        try copyMoltenVK(cxAppPath: cxAppPath, vulkanLibID: vulkanLibID)
    }

    guard let bottleURL = URL(string: selectedBottle) else {
        console.error("Invalid bottle URL: \(selectedBottle)")
        return
    }
    if(options == nil) {
        console.error("Missing game options for game with id \(id) - cannot launch (options = nil)")
        return
    }
    let f = FileManager.default

    var command = ""
    
    // registry
    let regOptionsDictionary: [String: UInt32] = [
        "DisableHidraw":options!.disableHidraw ? 1 : 0,
        "Enable SDL": options!.enableSDL ? 1 : 0
    ]
    
    let registryURL = bottleURL.appendingPathComponent("system.reg")
    let registry = WineRegistryFile(fileURL: registryURL)
    try registry.load()
    if let controllersSection = registry.section(forPath: "System\\\\CurrentControlSet\\\\Services\\\\winebus") {
        regOptionsDictionary.keys.forEach { key in
            let value = regOptionsDictionary[key]!
            console.log("setting \(key) to \(value)")
            controllersSection.addOrSetDword(forKey: key, value: value)
        }
        try registry.save()
    } else {
        console.error("\\\\winebus section not found in system.reg file for the bottle \(selectedBottle)")
    }
    
    console.warn("applying config changes to the bottle \(selectedBottle)...")
    
    let bottleName = URL(string: selectedBottle)?.lastPathComponent ?? ""
    console.warn("attempting to run steam.exe on game id \(id)")
    let arguments = options != nil ? " " + options!.gameArguments : ""
    let x87cxAppURL = f.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true).appendingPathComponent(PATCHED_CX_X87_APPNAME)
    let steamBootOptions = "-nochatui -nofriendsui -silent -no-browser -no-cef-sandbox -skipinitialbootstrap"
    let wineEnvs = "CX_ROOT=\"\(options!.x87PatchEnabled ? x87cxAppURL.path() : cxAppPath)/Contents/SharedSupport/CrossOver\" WINEPREFIX=\"\(URL(string: selectedBottle)?.path ?? "")\" WINEDEBUG=-all WINEMSYNC=\(options!.wineMSync ? "1" : "0")"
    
//    try cpyd8d9DLLs(to: bottleURL, enable: options!.dx9PatchEnabled)
    let normalizedPath = normalizeSteamPath(path: steamWinePath)
    let wineSteamPathArg = "\"" + normalizedPath.replacingOccurrences(of: "/", with: "\\") + "\" \(steamBootOptions) -applaunch \(String(id))"
    
    let gameLaunchCommand = appExeURL != nil ? "\"\(appExeURL!.path(percentEncoded: false))\"" : wineSteamPathArg
    if (options!.x87PatchEnabled) {
        if(!f.fileExists(atPath: x87cxAppURL.path())) {
            console.error("Couldn't find \(x87cxAppURL.path())")
            return
        }
        let workdirCommand = appExeURL != nil ? "cd \"\(appExeURL!.deletingLastPathComponent().path(percentEncoded: false))\" && " : ""
        command = "\(workdirCommand)env \(getInlineEnvs(from: options!) + wineEnvs) \(x87cxAppURL.path())Contents/SharedSupport/CrossOver/lib/wine/x86_64-unix/wine \(gameLaunchCommand) \(arguments)"
    } else {
        command = "env \(getInlineEnvs(from: options!) + wineEnvs) \(cxAppPath)/Contents/SharedSupport/CrossOver/bin/wine --bottle \(bottleName) \(gameLaunchCommand) \(arguments)"
    }
    
    #if DEBUG
    console.log(command)
    #endif
    try safeShell(command)
}

func launchNativeGame(id: String, cxAppPath: String, selectedBottle: String, options: GameOptions? = nil, appExeURL: URL? = nil) async throws {
    let arguments = options != nil ? " " + options!.gameArguments : ""
    let steamBootOptions = "-nochatui -nofriendsui -silent -no-browser -applaunch"
    var command = ""
    if(appExeURL != nil) {
        command = "env \(getInlineEnvs(from: options!)) open \"\(appExeURL!.path(percentEncoded: false))\" \(arguments)"
    } else {
        command = "env \(getInlineEnvs(from: options!)) /Applications/Steam.app/Contents/MacOS/steam_osx \(steamBootOptions) \(String(id)) \(arguments)"
    }
    console.warn(command)
    try safeShell(command)
}

func installGame(id: String) {
//    https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip
//    steamcmd +login YOUR_USERNAME +app_update 1489410 validate +quit
//    steamcmd +login USER +force_install_dir "C:\Program Files (x86)\Steam\steamapps\common\MyGame" +app_update 1489410 validate +quit
}

