//
// Copyright 2025 Wells Consulting.
// This file is part of Mirage and is released under the MIT License.
//

import Foundation

/// Persist encodable values.

public enum Settings {

    /// Load a value from UserDefaults.
    ///
    /// - Parameters
    ///     - key: Reference key.
    ///
    /// - Returns
    ///     - Value if stored at the given key, nil otherwise.
    ///
    /// - Throws:
    ///     JSONError if the value cannot be decoded.
    public static func load<T: Decodable>(key: String) throws -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        return try JSONCoder.shared.decode(data)
    }

    /// Save a value to UserDefaults.
    ///
    /// - Parameters
    ///     - value: Value to save.
    ///     - key: Reference key.
    ///
    /// - Throws:
    ///     JSONError if the value cannot be encoded.
    public static func save(_ value: some Encodable, key: String) throws {
        let data = try JSONCoder.shared.encode(value)
        UserDefaults.standard.set(data, forKey: key)
    }

    /// Remove a value from UserDefaults.
    public static func delete(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }

    /// Save strigified value to disk.
    ///
    /// - Parameters:
    ///     - value: Any encodable value.
    ///     - directory: Directory URL where the file will be saved.
    ///     - filename: Filename which will contain the value.
    ///
    /// - Throws:
    ///     - MirageError if the value cannot be converted into the data format.
    ///     - Error in the Cocoa domain if the data could not be written.
    public static func saveStringFile(of value: some Encodable, in directoryURL: URL, filename: String) throws {
        let resourceValues = try directoryURL.resourceValues(forKeys: [.isDirectoryKey])

        if let isDirectory = resourceValues.isDirectory {
            if isDirectory {
                // Directory exists and no file with that name is present
            } else {
                // A file with that name already exists, it will be overwritten
            }
        } else {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        let fileURL = directoryURL.appendingPathComponent(filename)

        let encodedValue = try JSONCoder.shared.encode(value)
        guard let jsonText = String(data: encodedValue, encoding: .utf8) else {
            throw Mirage.Error(description: "Failed to convert \"\(value.self)\" to a string.", title: "Stash Save Failed", context: ["url": fileURL, "data_size": encodedValue.count.formatted(.byteCount(style: .file))])
        }

        let data = Data(jsonText.utf8)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}
