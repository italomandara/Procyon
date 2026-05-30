//
//  INIConfigParser.swift
//  Procyon
//
//  Created by Coderdifference on 30/5/2026.
//
import Foundation

/// Returns all key=value pairs within the specified section of an INI-style config file at the given file path.
/// - Parameters:
///   - filePath: The path to the config file.
///   - section: The section header name to search for (case sensitive).
/// - Returns: A dictionary of key/value pairs found in the section, or an empty dictionary if the section is not found or the file cannot be read.
public func getConfigSection(filePath: String, section: String) -> [String: String] {
    guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
        return [:]
    }
    var result = [String: String]()
    var inSection = false
    for line in content.split(separator: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            inSection = (String(trimmed.dropFirst().dropLast()) == section)
            continue
        }
        if inSection && !trimmed.isEmpty && !trimmed.hasPrefix(";") {
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let rawKey = parts[0].trimmingCharacters(in: .whitespaces)
                let rawValue = parts[1].trimmingCharacters(in: .whitespaces)
                let key = rawKey.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                let value = rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                result[key] = value
            }
        }
    }
    return result
}

/// Returns all key=value pairs within the specified section of an INI-style config file at the given URL.
/// - Parameters:
///   - fileURL: The URL of the config file.
///   - section: The section header name to search for (case sensitive).
/// - Returns: A dictionary of key/value pairs found in the section, or an empty dictionary if the section is not found or the file cannot be read.
public func getConfigSection(fileURL: URL, section: String) -> [String: String] {
    return getConfigSection(filePath: fileURL.path, section: section)
}

