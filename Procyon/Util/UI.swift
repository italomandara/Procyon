//
//  UI.swift
//  Procyon
//
//  Created by Italo Mandara on 24/02/2026.
//

import UniformTypeIdentifiers
import AppKit

func openFolderSelectorPanel(type: UTType = .folder, title:String? = nil) -> URL? {
    let panel = NSOpenPanel()
    panel.title = title ?? "Select a Steam library folder (steamapps)";
    panel.allowsMultipleSelection = false;
    panel.canChooseDirectories = true;
    panel.allowedContentTypes = [type]
    return panel.runModal() == .OK ? panel.url?.absoluteURL : nil
}
