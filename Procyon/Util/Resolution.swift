//
//  Resolution.swift
//  Procyon
//
//  Resolution configuration for CrossOver bottles using Wine registry.
//  Based on CXRes logic.
//

import AppKit

struct ResolutionProfile: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var resolution: String
}

struct ResolutionState {
    var isVirtualDesktopEnabled: Bool
    var resolution: String // e.g. "1920x1080"
    var dpi: UInt32         // e.g. 96
}

class BottleResolutionManager {
    private let bottleURL: URL
    private let registryFile: WineRegistryFile

    private let explorerPath = "Software\\\\Wine\\\\Explorer"
    private let desktopsPath = "Software\\\\Wine\\\\Explorer\\\\Desktops"
    private let fontsPath = "Software\\\\Wine\\\\Fonts"

    init(bottleURL: URL) {
        self.bottleURL = bottleURL
        let regURL = bottleURL.appendingPathComponent("user.reg")
        self.registryFile = WineRegistryFile(fileURL: regURL)
    }

    // MARK: - Read

    func loadCurrentState() throws -> ResolutionState {
        try registryFile.load()

        let explorerSection = registryFile.section(forPath: explorerPath)
        let desktopsSection = registryFile.section(forPath: desktopsPath)
        let fontsSection = registryFile.section(forPath: fontsPath)

        let desktopValue = explorerSection?.getValue(forKey: "Desktop") ?? ""
        let isEnabled = !desktopValue.isEmpty
        let resolution = desktopsSection?.getValue(forKey: "Default") ?? "1920x1080"
        let dpiStr = fontsSection?.getValue(forKey: "LogPixels") ?? "96"
        let dpi = UInt32(dpiStr) ?? 96

        return ResolutionState(
            isVirtualDesktopEnabled: isEnabled,
            resolution: resolution,
            dpi: dpi
        )
    }

    // MARK: - Write

    func applyResolution(_ resolution: String?, dpi: UInt32? = nil) throws {
        try registryFile.load()

        let explorerSection = registryFile.section(forPath: explorerPath)
        let desktopsSection = registryFile.section(forPath: desktopsPath)

        if let resolution = resolution {
            // Enable virtual desktop with given resolution
            explorerSection?.addOrSetValue(forKey: "Desktop", stringValue: "Default")
            desktopsSection?.addOrSetValue(forKey: "Default", stringValue: resolution)
            console.log("Setting resolution to \(resolution)")
        } else {
            // Disable virtual desktop
            explorerSection?.addOrSetValue(forKey: "Desktop", stringValue: "")
            console.log("Disabling virtual desktop")
        }

        if let dpi = dpi {
            let fontsSection = registryFile.section(forPath: fontsPath)
            fontsSection?.setDword(forKey: "LogPixels", value: dpi)
            console.log("Setting DPI to \(dpi)")
        }

        try registryFile.save()
    }

    func disableVirtualDesktop() throws {
        try applyResolution(nil)
    }

    // MARK: - Display detection

    static func detectDisplayProfiles() -> [ResolutionProfile] {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            return [ResolutionProfile(name: "Default", resolution: "1920x1080")]
        }
        var profiles: [ResolutionProfile] = []
        var seen = Set<String>()
        for screen in screens {
            let backing = screen.convertRectToBacking(screen.frame)
            let w = Int(backing.width)
            let h = Int(backing.height)
            let res = "\(w)x\(h)"
            guard !seen.contains(res) else { continue }
            seen.insert(res)
            let name = screen == screens.first ? "Built-in" : "External"
            profiles.append(ResolutionProfile(name: name, resolution: res))
        }
        return profiles
    }
}
