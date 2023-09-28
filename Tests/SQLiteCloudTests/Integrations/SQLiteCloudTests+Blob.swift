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

import XCTest
@testable import SQLiteCloud

final class SQLiteCloudTests_Blob: XCTestCase {
    private var hostname: String = .empty
    private var username: String = .empty
    private var password: String = .empty
    private var cloud: SQLiteCloud!
    
    private var firstLength: Int = 0
    private var firstRandomData: Data = .empty
    
    override func setUp() async throws {
        hostname = ProcessInfo.processInfo.environment["SQ_LITE_CLOUD_HOST"] ?? .empty
        username = ProcessInfo.processInfo.environment["SQ_LITE_CLOUD_USER"] ?? .empty
        password = ProcessInfo.processInfo.environment["SQ_LITE_CLOUD_PASS"] ?? .empty
        
        let config = SQLiteCloudConfig(hostname: hostname, username: username, password: password)
        cloud = SQLiteCloud(config: config)
        try await cloud.connect()
        
        _ = try await cloud.execute(command: .useDatabase(name: "mydatabase"))
        _ = try await cloud.execute(query: """
        CREATE TABLE IF NOT EXISTS Test1  (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            data BLOB
        );
        """)
        
        _ = try await cloud.execute(query: "DELETE FROM Test1")
        
        firstLength = Int.random(in: 1...1_000_000)
        firstRandomData = Data.random(length: firstLength)
        
        let command = SQLiteCloudCommand(query: "INSERT INTO Test1 (id, name, data) VALUES (1, ?, ?)", .string("RandomString1"), .blob(firstRandomData))
        _ = try await cloud.execute(command: command)
    }
    
    override func tearDown() async throws {
        _ = try await cloud.execute(query: "DROP TABLE IF EXISTS Test1")
    }
    
    func test_updateBlob_withRandomData_shouldUpdateBlobWithoutError() async throws {
        let length = Int.random(in: 1...1_000_000)
        let randomData = Data.random(length: length)
        let blob = SQLiteCloudBlobWrite(table: "Test1", column: "data", rowId: 1, data: randomData)
        try await cloud.update(blob: blob)
    }
    
    func test_updateBlob_withRandomData_shouldReadBlobWithoutError() async throws {
        let blob = SQLiteCloudBlobRead(table: "Test1", column: "data", row: .init(rowId: 1, dataDestination: .data))
        let data = try await cloud.read(blob: blob)
        XCTAssertEqual(data.count, 1)
        XCTAssertEqual(data.first?.data?.count, firstRandomData.count)
    }
}
