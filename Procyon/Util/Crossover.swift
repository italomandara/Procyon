//
//  Crossover.swift
//  Procyon
//
//  Created by Italo Mandara on 26/02/2026.
//

import Foundation

func getCXDefaultBottlesURL() -> URL {
    let appID = "com.codeweavers.CrossOver" as CFString
    let key = "BottleDir" as CFString
    guard let bottlesPath = CFPreferencesCopyAppValue(key, appID) else {
        console.error("CrossOver preference 'BottleDir' not found")
        let fallback = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(DEFAULT_BOTTLE_PATH, isDirectory: true)
        return fallback
    }

    return URL(filePath: bottlesPath as! String)
}

func isCXPatched(appDir: URL) -> Bool {
    let f = FileManager.default
    return f.fileExists(atPath: appDir.appendingPathComponent("Contents/cxplog.txt").path(percentEncoded: false))
}

func getCXPatcherBottlesURL(appDir: URL)  throws -> URL {
    let f = FileManager.default
    let base = f.homeDirectoryForCurrentUser
    
    let confPath: URL = appDir.appendingPathComponent("/Contents/SharedSupport/CrossOver/etc/CrossOver.conf")
    console.log("Loading CrossOver configurationf from \(confPath.path) ...")
    let envSection = getConfigSection(fileURL: confPath, section: "EnvironmentVariables")
    console.log("Finding CX_BOTTLE_PATH in configuration ...")
    let cxBottlePath = envSection["CX_BOTTLE_PATH"]
    if let cxBottlePath {
        console.log("Found CX_BOTTLE_PATH in configuration: \(cxBottlePath)")

        if cxBottlePath.hasPrefix("/Users/${USER}/") {
            console.log("Found user based path, transforming to local user path ...")
            let components = cxBottlePath.split(separator: "/").dropFirst(2) // ["Users", "${USER}", "..."]
            let path = components.joined(separator: "/")
            return base.appendingPathComponent(path, isDirectory: true)
        } else {
            return URL(filePath: cxBottlePath)
        }
    }
    
    // fallback if it doesn't find it in the config file (just in case)
    console.warn("Couldn't find CXPatcher bottles configuration: " + confPath.absoluteString)
    let bottlePathForCXP: URL = PROCYON_SUPPORT_FOLDER_URL.appendingPathComponent(DEFAULT_CXP_BOTTLES_FOLDER, isDirectory: true)
    return bottlePathForCXP
}

func getAllBottles(appDir: URL) throws -> [URL] {
    let f = FileManager.default
    let FORCE_IS_CXPATCHED = true
    
    
    var subfolders: [URL] = []
    
    if(FORCE_IS_CXPATCHED || isCXPatched(appDir: appDir)) {
        let bottleURLForCXP = try getCXPatcherBottlesURL(appDir: appDir)
        console.log("app is patched with CXPatcher")
        do {
            subfolders = try f.contentsOfDirectory(at: bottleURLForCXP, includingPropertiesForKeys: [.isDirectoryKey], options: [])
        } catch {
            console.error(String(reflecting: error))
            console.error("couldn't find the CXPatched bottles")
        }
    } else {
        let bottlePath = getCXDefaultBottlesURL()
        console.warn(bottlePath.absoluteString)
        console.log("app is normal crossover")
        do {
            subfolders = try f.contentsOfDirectory(at: bottlePath, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
        } catch {
            console.error(String(reflecting: error))
            console.error("couldn't find the crossover bottles in \(bottlePath.path(percentEncoded: false))")
        }
    }
    console.warn("subfolders \(subfolders.debugDescription)")
    let filtered = subfolders.filter { url in
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    console.warn("filtered: \(filtered.debugDescription)")
    return filtered
}

func modifyBottleSettingOptions(selectedBottle: String, options: [String: String]) {
    options.forEach { option in
        console.warn("key: \(option.key), value: \(option.value)")
    }
}

func getCXBottleConfigFileURL(selectedBottle: String) -> URL? {
    return URL(string: selectedBottle)?.appendingPathComponent("cxbottle.conf")
}

func editCXBottleConfigFile(selectedBottle: String, options: [String: String]) throws {
    if let bottleURL = getCXBottleConfigFileURL(selectedBottle: selectedBottle) {
        let original = try String(contentsOf: bottleURL, encoding: .utf8)
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
        try updated.write(to: bottleURL, atomically: true, encoding: .utf8)
    } else {
        console.error("No bottle selected in Procyon config")
    }
}

func stripEnvsInCXBottleConfigFile(selectedBottle: String) throws {
    if let bottleURL = getCXBottleConfigFileURL(selectedBottle: selectedBottle) {
        let original = try String(contentsOf: bottleURL, encoding: .utf8)
        let lines = original.components(separatedBy: .newlines)
        if let index = lines.firstIndex(of: "[EnvironmentVariables]") {
            let newLines = lines[0..<index+1] + [";;\"PROMPT\" = \"$p$g\""]
            let updated = newLines.joined(separator: "\n")
            try updated.write(to: bottleURL, atomically: true, encoding: .utf8)
        }
    } else {
        console.error("No bottle selected in Procyon config")
    }
}

func getDxmtConfigEnv(values: [String]) -> String {
    return values.count == 0 ? "" : "DXMT_CONFIG=\"\(values.joined(separator: ";"))\" "
}

func getInlineEnvs(from: GameOptions) -> String {
    /**
     @TO DO:
     "MVK_CONFIG_FAST_MATH", "1"
     "MVK_CONFIG_PREFILL_METAL_COMMAND_BUFFERS", "3"
     "MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS", "1"
     "MVK_CONFIG_USE_MTLHEAP", "2"
     MVK_CONFIG_SYNCHRONOUS_QUEUE_SUBMITS=1 -> used by d9vk
     
     # 1. Point to your driver
     export VK_ICD_FILENAMES="/Volumes/Card/code/mesa/build_x86/src/kosmickrisp/vulkan/kosmickrisp_mesa_icd.x86_64.json"

     # 2. Tell the loader to ignore MoltenVK and use ONLY your driver
     export VK_ICD_FILENAMES_ONLY=1

     # 3. Disable the "Portability" check that confuses old DXVK
     export VK_KHR_PORTABILITY_ENUMERATION=0

     # 4. Force DXVK to accept the "Conformant" surface KosmicKrisp provides
     export DXVK_WSI_DRIVER="vulkan"
     export DXVK_CONFIG="dxvk.allowNativeVulkan = True"
     */
    func DoubleToFormattedStr(_ value: Double, _ digits: Int = 2) -> String {
        return String(value.formatted(.number.precision(.fractionLength(0...digits))))
    }
    func onOff(_ value: Bool?) -> String {
        return value != nil && value == true ? "1" : "0"
    }
    var value = from.envVariables == "" ? "" : "\(from.envVariables) "
    let defaults = [
        "D3DM_ENABLE_METALFX=1",
        "DXMT_ENABLE_NVEXT=1",
        "DXVK_ASYNC=1",
//        "MVK_CONFIG_SYNCHRONOUS_QUEUE_SUBMITS=1", //slower, but more reliable
//        "MVK_CONFIG_PREFILL_METAL_COMMAND_BUFFERS=3", //this actually slows down everything
//        "MVK_CONFIG_USE_MTLHEAP=2",
//        "D3DM_MTL4=1",
//        "D3DM_MAX_FPS=60",
    ]
    value += defaults.joined(separator: " ") + " "
    value += from.mtlHudEnabled ? "MTL_HUD_ENABLED=1 " : ""
    value += from.ue4Hack ? "MVK_CONFIG_UE4_HACK_ENABLED=1 NAS_DISABLE_UE4_HACK=0 " : "MVK_CONFIG_UE4_HACK_ENABLED=0 NAS_DISABLE_UE4_HACK=1 "
    value += from.mvkArgBuff ? "MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS=1 " : "MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS=0 "
    value += "ROSETTA_ADVERTISE_AVX=\(onOff(from.advertiseAVX)) "
    value += "CX_GRAPHICS_BACKEND=\"\(from.cxGraphicsBackend)\" "
    value += from.d3dMtl4Enabled ? "D3DM_MTL4=1 " : ""
    value += from.d3dMaxFPS != 0 ? "D3DM_MAX_FPS=\(from.d3dMaxFPS) " : ""
//    switch (from.vulkanLib) {
//        case "latest":
//            if let url = Bundle.main.url(forResource: "libMoltenVK-latest", withExtension: "dylib") {
//                value += "CX_LIBVULKAN=\"\(url.path(percentEncoded: false))\" "
//            }
//        case "experimental":
//            if let url = Bundle.main.url(forResource: "libMoltenVK-experimental", withExtension: "dylib") {
//                value += "CX_LIBVULKAN=\"\(url.path(percentEncoded: false))\" "
//            }
//        case "experimental2":
//            if let url = Bundle.main.url(forResource: "libMoltenVK-experimental2", withExtension: "dylib") {
//                value += "CX_LIBVULKAN=\"\(url.path(percentEncoded: false))\" "
//            }
//        //    case "kosmickrisp":
//        //        if let url = Bundle.main.url(forResource: "libvulkan_kosmickrisp", withExtension: "dylib") {
//        //            value += "CX_LIBVULKAN=\"\(url.path(percentEncoded: false))\" "
//        //        }
//        default:
//            break
//    }
    let dxmtMetalFXSpatial = from.dxmtMetalFXSpatial ? "DXMT_METALFX_SPATIAL_SWAPCHAIN=1 " : ""
    value += dxmtMetalFXSpatial
    
    var dxmtConfigValues: [String] = []
    if from.dxmtPreferredMaxFrameRate > 20 {
        dxmtConfigValues.append("d3d11.preferredMaxFrameRate=\(DoubleToFormattedStr(from.dxmtPreferredMaxFrameRate))")
    }
    if from.dxmtMetalFXSpatial == true  {
        dxmtConfigValues.append("d3d11.metalSpatialUpscaleFactor=\(from.dxmtMetalSpatialUpscaleFactor)")
    }
    
    if (from.x87PatchEnabled) {
        if let runtimex87Url = Bundle.main.url(forResource: "runtime_loader", withExtension: nil) {
            value += "ROSETTA_X87_PATH=\"\(runtimex87Url.path())\" "
        } else {
            console.error("Couldn't find runtime_loader")
        }
    }
    
    value += getDxmtConfigEnv(values:  dxmtConfigValues)
    return value
}

func toCrossoverENVString(_ key: String, _ value: String) -> String {
    return "\"\(key)\" = \"\(value)\""
}

func parseCXEnvVarString(_ string: String) -> (String, String){
    // "KEY"="VALUE"
    // e.g.: "CX_BOTTLE_PATH"="/Users/${USER}/CXPBottles"
    let regex = /\"(\w+?)\"\=\"(.+?)\"/
    var key = ""
    var value = ""
    do {
        let match = try regex.firstMatch(in: string)
        key = match?.1.description ?? ""
        value = match?.2.description ?? ""
    } catch {
        console.error("parseCXEnvVarString: \(String(reflecting: error))")
    }
    return (key, value)
}

func getBottleDrives(bottleURL: URL) -> CXDrives {
    let at = bottleURL.appendingPathComponent("dosdevices", isDirectory: true)
    return getDrivesPaths(at: at)
}

func getDrivesPaths(at: URL) -> CXDrives {
    let f = FileManager.default
    do {
        let simLinks = try f.contentsOfDirectory(at: at , includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        let drives = try simLinks.reduce(into: [String: URL]()) { result, link in
            let key = link.lastPathComponent.uppercased()
            let value = try f.destinationOfSymbolicLink(atPath: link.path(percentEncoded: false))
            if (value.contains("drive_c")) {
                result[key] = at.deletingLastPathComponent().appendingPathComponent("drive_c")
            } else {
                result[key] = URL(filePath: value)
            }
        }
        
        return drives
    } catch {
        console.error("getDrivesPaths failed")
        console.error(String(reflecting: error))
        return [:]
    }
}

func createBottle(cxAppPath: String, bottleName: String = "Steam", template: String = "win10_64") throws -> Process {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: cxAppPath).appendingPathComponent("/Contents/SharedSupport/CrossOver/bin/cxbottle")
    proc.arguments = ["--create", "--bottle", bottleName, "--template", template]
    try proc.run()
    return proc
}

func install(cxAppPath: String, bottleName: String = "Steam", template: String = "win10_64") throws -> Process {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: cxAppPath).appendingPathComponent("/Contents/SharedSupport/CrossOver/bin/cxbottle")
    proc.arguments = ["--create", "--bottle", bottleName, "--template", template]
    try proc.run()
    return proc
}
