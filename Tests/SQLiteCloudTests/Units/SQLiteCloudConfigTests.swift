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

final class SQLiteCloudConfigTests: XCTestCase {
    let hostname = "test-hostname"
    let username = "test-username"
    let password = "test-password"
    let database = "test-database"
    let port = SQLiteCloudConfig.Port.custom(portNumber: Int.random(in: 0..<1000))
    let family = SQLiteCloudConfig.Family.ipv6
    let passwordHashed = Bool.random()
    let nonlinearizable = Bool.random()
    let timeout = Int.random(in: 0..<1000)
    let compression = Bool.random()
    let sqliteMode = Bool.random()
    let zerotext = Bool.random()
    let memory = Bool.random()
    let dbCreate = Bool.random()
    let insecure = Bool.random()
    let noblob = Bool.random()
    let maxData = Int.random(in: 0..<1000)
    let maxRows = Int.random(in: 0..<1000)
    let maxRowset = Int.random(in: 0..<1000)
    let rootCertificate = "test-rootCertificate"
    let clientCertificate = "test-clientCertificate"
    let clientCertificateKey = "test-clientCertificateKey"
    
    func test_init_withValidParameters_shouldHaveValidFieldValues() async throws {
        let config = SQLiteCloudConfig(hostname: hostname,
                                       username: username,
                                       password: password,
                                       port: port,
                                       family: family,
                                       passwordHashed: passwordHashed,
                                       nonlinearizable: nonlinearizable,
                                       timeout: timeout,
                                       compression: compression,
                                       sqliteMode: sqliteMode,
                                       zerotext: zerotext,
                                       memory: memory,
                                       dbCreate: dbCreate,
                                       insecure: insecure,
                                       noblob: noblob,
                                       maxData: maxData,
                                       maxRows: maxRows,
                                       maxRowset: maxRowset,
                                       rootCertificate: rootCertificate,
                                       clientCertificate: clientCertificate,
                                       clientCertificateKey: clientCertificateKey)
        
        XCTAssertEqual(hostname, config.hostname)
        XCTAssertEqual(username, config.username)
        XCTAssertEqual(password, config.password)
        XCTAssertEqual(port, config.port)
        XCTAssertEqual(family, config.family)
        XCTAssertEqual(passwordHashed, config.passwordHashed)
        XCTAssertEqual(nonlinearizable, config.nonlinearizable)
        XCTAssertEqual(timeout, config.timeout)
        XCTAssertEqual(compression, config.compression)
        XCTAssertEqual(sqliteMode, config.sqliteMode)
        XCTAssertEqual(zerotext, config.zerotext)
        XCTAssertEqual(memory, config.memory)
        XCTAssertEqual(dbCreate, config.dbCreate)
        XCTAssertEqual(insecure, config.insecure)
        XCTAssertEqual(noblob, config.noblob)
        XCTAssertEqual(maxData, config.maxData)
        XCTAssertEqual(maxRows, config.maxRows)
        XCTAssertEqual(maxRowset, config.maxRowset)
        XCTAssertEqual(rootCertificate, config.rootCertificate)
        XCTAssertEqual(clientCertificate, config.clientCertificate)
        XCTAssertEqual(clientCertificateKey, config.clientCertificateKey)
    }
    
    func test_init_withValidConnection_shouldHaveValidFieldValues() async throws {
        let connectionString = "sqlitecloud://\(username):\(password)@\(hostname):\(port.number)/\(database)?timeout=\(timeout)"
        let config = SQLiteCloudConfig(connectionString: connectionString)
        
        XCTAssertEqual(hostname, config?.hostname)
        XCTAssertEqual(username, config?.username)
        XCTAssertEqual(password, config?.password)
        XCTAssertEqual(port, config?.port)
        XCTAssertEqual(database, config?.dbname)
        XCTAssertEqual(timeout, config?.timeout)
    }
}
