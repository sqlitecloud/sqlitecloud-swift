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

public struct SQLiteCloudConfig: Sendable {
    public let hostname: String
    public let port: Port
    public let username: String?
    public let password: String?
    public let apiKey: String?
    public let family: Family
    public let passwordHashed: Bool
    public let nonlinearizable: Bool
    public let timeout: Int
    public let compression: Bool
    public let zerotext: Bool
    public let memory: Bool
    public let dbCreate: Bool
    public let insecure: Bool
    public let noblob: Bool
    public let isReadonlyConnection: Bool
    public let maxData: Int
    public let maxRows: Int
    public let maxRowset: Int
    public let dbname: String?
    public let rootCertificate: String?
    public let clientCertificate: String?
    public let clientCertificateKey: String?
    
    public init(hostname: String,
                apiKey: String,
                port: Port = .default,
                family: Family = .ipv4,
                passwordHashed: Bool = false,
                nonlinearizable: Bool = false,
                timeout: Int = 0,
                compression: Bool = false,
                zerotext: Bool = false,
                memory: Bool = false,
                dbCreate: Bool = false,
                insecure: Bool = false,
                noblob: Bool = false,
                isReadonlyConnection: Bool = false,
                maxData: Int = 0,
                maxRows: Int = 0,
                maxRowset: Int = 0,
                dbname: String? = nil,
                rootCertificate: String? = nil,
                clientCertificate: String? = nil,
                clientCertificateKey: String? = nil) {
        self.init(hostname: hostname,
                  username: nil,
                  password: nil,
                  apiKey: apiKey,
                  port: port,
                  family: family,
                  passwordHashed: passwordHashed,
                  nonlinearizable: nonlinearizable,
                  timeout: timeout,
                  compression: compression,
                  zerotext: zerotext,
                  memory: memory,
                  dbCreate: dbCreate,
                  insecure: insecure,
                  noblob: noblob,
                  isReadonlyConnection: isReadonlyConnection,
                  maxData: maxData,
                  maxRows: maxRows,
                  maxRowset: maxRowset,
                  dbname: dbname,
                  rootCertificate: rootCertificate,
                  clientCertificate: clientCertificate,
                  clientCertificateKey: clientCertificateKey)
    }

    public init(hostname: String,
                username: String,
                password: String,
                port: Port = .default,
                family: Family = .ipv4,
                passwordHashed: Bool = false,
                nonlinearizable: Bool = false,
                timeout: Int = 0,
                compression: Bool = false,
                zerotext: Bool = false,
                memory: Bool = false,
                dbCreate: Bool = false,
                insecure: Bool = false,
                noblob: Bool = false,
                isReadonlyConnection: Bool = false,
                maxData: Int = 0,
                maxRows: Int = 0,
                maxRowset: Int = 0,
                dbname: String? = nil,
                rootCertificate: String? = nil,
                clientCertificate: String? = nil,
                clientCertificateKey: String? = nil) {
        self.init(hostname: hostname,
                  username: username,
                  password: password,
                  apiKey: nil,
                  port: port,
                  family: family,
                  passwordHashed: passwordHashed,
                  nonlinearizable: nonlinearizable,
                  timeout: timeout,
                  compression: compression,
                  zerotext: zerotext,
                  memory: memory,
                  dbCreate: dbCreate,
                  insecure: insecure,
                  noblob: noblob,
                  isReadonlyConnection: isReadonlyConnection,
                  maxData: maxData,
                  maxRows: maxRows,
                  maxRowset: maxRowset,
                  dbname: dbname,
                  rootCertificate: rootCertificate,
                  clientCertificate: clientCertificate,
                  clientCertificateKey: clientCertificateKey)
    }

    private init(hostname: String,
                username: String?,
                password: String?,
                 apiKey: String?,
                port: Port = .default,
                family: Family = .ipv4,
                passwordHashed: Bool = false,
                nonlinearizable: Bool = false,
                timeout: Int = 0,
                compression: Bool = false,
                zerotext: Bool = false,
                memory: Bool = false,
                dbCreate: Bool = false,
                insecure: Bool = false,
                noblob: Bool = false,
                isReadonlyConnection: Bool = false,
                maxData: Int = 0,
                maxRows: Int = 0,
                maxRowset: Int = 0,
                dbname: String? = nil,
                rootCertificate: String? = nil,
                clientCertificate: String? = nil,
                clientCertificateKey: String? = nil) {
        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
        self.apiKey = apiKey
        self.family = family
        self.passwordHashed = passwordHashed
        self.nonlinearizable = nonlinearizable
        self.timeout = timeout
        self.compression = compression
        self.zerotext = zerotext
        self.memory = memory
        self.dbCreate = dbCreate
        self.insecure = insecure
        self.noblob = noblob
        self.isReadonlyConnection = isReadonlyConnection
        self.maxData = maxData
        self.maxRows = maxRows
        self.maxRowset = maxRowset
        self.dbname = dbname
        self.rootCertificate = rootCertificate
        self.clientCertificate = clientCertificate
        self.clientCertificateKey = clientCertificateKey
    }

    public init?(connectionString: String) {
        guard let url = URL(string: connectionString) else { return nil }
        
        self.init(connectionURL: url)
    }
    
    /// sqlitecloud://user:pass@host.com:port/dbname?timeout=10&key2=value2&key3=value3.
    public init?(connectionURL: URL) {
        guard let hostname = connectionURL.host else { return nil }

        let urlComponents = URLComponents(string: connectionURL.absoluteString)
        let queryItems = urlComponents?.queryItems

        // There are 2 kind of possibile credentials types
        // - based on an apikey
        // - based on the username and the password combo
        // We need to search for this credential info in the connection string.
        // First we check for apikey, if fails we fallback on the user/pass combo.

        if let apiKey = UrlParser.parse(items: queryItems, name: "apikey") {
            self.username = nil
            self.password = nil
            self.apiKey = apiKey
        } else {
            guard let username = connectionURL.user else { return nil }
            guard let password = connectionURL.password else { return nil }

            self.username = username
            self.password = password
            self.apiKey = nil
        }

        let port = connectionURL.port.map { Port.custom(portNumber: $0) } ?? .default

        // external
        self.hostname = hostname
        self.port = port
        self.isReadonlyConnection = UrlParser.parse(items: queryItems, name: "readonly")
        
        // in config
        self.dbname = urlComponents?.path.replacingOccurrences(of: "/", with: "")
        self.family = Family(rawValue: UrlParser.parse(items: queryItems, name: "family")) ?? .ipv4
        self.passwordHashed = UrlParser.parse(items: queryItems, name: "passwordHashed")
        self.nonlinearizable = UrlParser.parse(items: queryItems, name: "nonlinearizable")
        
        // in query
        self.timeout = UrlParser.parse(items: queryItems, name: "timeout")
        self.compression = UrlParser.parse(items: queryItems, name: "compression")
        self.zerotext = UrlParser.parse(items: queryItems, name: "zerotext")
        self.memory = UrlParser.parse(items: queryItems, name: "memory")
        self.dbCreate = UrlParser.parse(items: queryItems, name: "create")
        self.insecure = UrlParser.parse(items: queryItems, name: "insecure")
        self.noblob = UrlParser.parse(items: queryItems, name: "noblob")
        self.maxData = UrlParser.parse(items: queryItems, name: "maxdata")
        self.maxRows = UrlParser.parse(items: queryItems, name: "maxrows")
        self.maxRowset = UrlParser.parse(items: queryItems, name: "maxrowset")
        self.rootCertificate = UrlParser.parse(items: queryItems, name: "root_certificate")
        self.clientCertificate = UrlParser.parse(items: queryItems, name: "client_certificate")
        self.clientCertificateKey = UrlParser.parse(items: queryItems, name: "client_certificate_key")
    }
}

extension SQLiteCloudConfig {
    var connectionString: String {
        if let apiKey {
            "sqlitecloud://\(hostname):\(port.number)/\(dbname ?? .empty)?apikey=\(apiKey)"
        } else {
            "sqlitecloud://\(username ?? ""):****@\(hostname):\(port.number)/\(dbname ?? .empty)"
        }
    }
}

// MARK: - Nested types

public extension SQLiteCloudConfig {
    /// The TCP port number used to connect to the cloud.
    enum Port: Equatable, Sendable {
        /// The port default is `SQCLOUD_DEFAULT_PORT 8860`
        case `default`
        
        /// Custom port number.
        case custom(portNumber: Int)
        
        /// Returns the port number.
        var number: Int32 {
            switch self {
            case .`default`:
                return 8_860
                
            case .custom(portNumber: let portNumber):
                return Int32(portNumber)
            }
        }
    }
    
    /// Constants that describe the connection family.
    enum Family: Int32, Sendable {
        case ipv4 = 0
        case ipv6 = 1
        case ipvAny = 2
    }
}
