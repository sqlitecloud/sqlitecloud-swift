//
//  SQLiteCloud
//
//  Created by Massimo Oliviero.
//
//  Copyright (c) 2023 SQLite Cloud, Inc. (https://sqlitecloud.io/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

/// Represents a database file to be uploaded to the SQLite Cloud server.
///
/// Use the `SQLiteCloudUploadDatabase` struct to specify the database file you 
/// want to upload to the SQLite Cloud server. It includes the following information:
///
/// - `url`: The URL of the database file on the local system.
/// - `name`: The name of the database as it should appear on the SQLite Cloud server.
/// - `encryptionKey`: An optional encryption key for the database file, if it's encrypted.
///
/// Example usage:
///
/// ```swift
/// let databaseURL = URL(fileURLWithPath: "/path/to/your/database.db")
/// let uploadDatabase = SQLiteCloudUploadDatabase(url: databaseURL, databaseName: "mydb", encryptionKey: "your_key")
/// ```
public struct SQLiteCloudUploadDatabase: Sendable {
    public let url: URL
    public let name: String
    public let encryptionKey: String?
    
    /// Initializes a new `SQLiteCloudUploadDatabase` instance with the provided parameters.
    ///
    /// Use this initializer to create a `SQLiteCloudUploadDatabase` object with the necessary 
    /// information to specify a database file for upload to the SQLite Cloud server.
    ///
    /// - Parameters:
    ///   - url: The URL of the database file on the local system.
    ///   - name: The name of the database as it should appear on the SQLite Cloud server.
    ///   - encryptionKey: An optional encryption key for the database file, if it's encrypted. Default is `nil`.
    ///
    /// - Note: If the `encryptionKey` parameter is provided, the database file will be expected
    ///         to be encrypted with the specified key when uploaded to the SQLite Cloud server.
    public init(url: URL, name: String, encryptionKey: String? = nil) {
        self.url = url
        self.name = name
        self.encryptionKey = encryptionKey
    }
}
