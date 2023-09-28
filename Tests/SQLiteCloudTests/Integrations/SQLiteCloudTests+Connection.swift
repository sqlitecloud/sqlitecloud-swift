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

final class SQLiteCloudTests_Connection: XCTestCase {
    private var hostname: String = .empty
    private var username: String = .empty
    private var password: String = .empty

    override func setUpWithError() throws {
        hostname = ProcessInfo.processInfo.environment["SQ_LITE_CLOUD_HOST"] ?? .empty
        username = ProcessInfo.processInfo.environment["SQ_LITE_CLOUD_USER"] ?? .empty
        password = ProcessInfo.processInfo.environment["SQ_LITE_CLOUD_PASS"] ?? .empty
    }

    func test_connect_withValidCredentials_shouldConnectWithoutError() async throws {
        let config = SQLiteCloudConfig(hostname: hostname, username: username, password: password)
        let cloud = SQLiteCloud(config: config)
        
        do {
            try await cloud.connect()
        } catch {
            XCTFail("An error was thrown: \(error)")
        }
    }
    
    func test_connect_withInvalidCredentials_shouldThrowError() async throws {
        let config = SQLiteCloudConfig(hostname: hostname, username: "!!invalid!!", password: "!!credentials!!")
        let cloud = SQLiteCloud(config: config)
        
        do {
            try await cloud.connect()
            XCTFail("No errors were thrown.")
        } catch {
            XCTAssert(error is SQLiteCloudError)
        }
    }
    
    func test_disconnect_withValidConnection_shouldDisconnectWithoutError() async throws {
        let config = SQLiteCloudConfig(hostname: hostname, username: username, password: password)
        let cloud = SQLiteCloud(config: config)
        
        do {
            try await cloud.connect()
            try await cloud.disconnect()
        } catch {
            XCTFail("An error was thrown: \(error)")
        }
    }
    
    func test_disconnect_withInvalidConnection_shouldThrowError() async throws {
        let config = SQLiteCloudConfig(hostname: hostname, username: "!!invalid!!", password: "!!credentials!!")
        let cloud = SQLiteCloud(config: config)
        
        do {
            try await cloud.disconnect()
            XCTFail("No errors were thrown.")
        } catch {
            XCTAssert(error is SQLiteCloudError)
        }
    }
}
