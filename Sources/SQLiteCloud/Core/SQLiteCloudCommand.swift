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

public struct SQLiteCloudCommand: Sendable {
    public var query: String
    public var parameters: [SQLiteCloudValue]
    
    public init(query: String, parameters: [SQLiteCloudValue] = []) {
        self.query = query
        self.parameters = parameters
    }
    
    public init(query: String, _ parameters: SQLiteCloudValue...) {
        self.query = query
        self.parameters = parameters
    }
}

public extension SQLiteCloudCommand {
    static func expandBlob(table: String, column: String, rowId: Int, size: Int) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "UPDATE \(table) SET \(column) = zeroblob(?) WHERE rowId = ?;",
                           parameters: [.integer(size), .integer(rowId)])
    }
}

public extension SQLiteCloudCommand {
    static func useDatabase(name: String) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "USE DATABASE ?;", parameters: [.string(name)])
    }
    
    static func getClient(keyname: String) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "GET CLIENT KEY ?", parameters: [.string(keyname)])
    }
    
    static func getKey(keyname: String) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "GET KEY", parameters: [.string(keyname)])
    }
    
    static func getRuntimeKey(keyname: String) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "GET RUNTIME KEY ?", parameters: [.string(keyname)])
    }
    
    static func getDatabaseKey(database: String, keyname: String) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "GET DATABASE ? KEY ?", parameters: [.string(database), .string(keyname)])
    }
    
    static let getLeader = SQLiteCloudCommand(query: "GET LEADER;")
    static let getLeaderId = SQLiteCloudCommand(query: "GET LEADER ID;")
}

// MARK: - General

public extension SQLiteCloudCommand {
    /// The LIST TABLES command retrieves the information about the tables available inside the current database.
    /// Note that the output of this command can change depending on the privileges associated with the currently
    /// connected username. If the PUBSUB parameter is used, then the output will contain the column chname only
    /// (to have the same format as the rowset returned by the LIST CHANNELS command).
    static let listTables = SQLiteCloudCommand(query: "LIST TABLES;")
    
    /// The GET INFO command retrieves a single specific information about a key. The NODE argument forces the
    /// execution of the command to a specific node of the cluster.
    ///
    /// - Parameter key: The information key.
    /// - Returns: An instance of `SQLiteCloudCommand`.
    static func getInfo(key: String) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "GET INFO ?", parameters: [.string(key)])
    }
    
    /// The GET SQL command retrieves the SQL statement used to generate the table name.
    ///
    /// - Parameter tableName: The name of the table.
    /// - Returns: An instance of `SQLiteCloudCommand`.
    static func getSQL(tableName: String) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "GET SQL ?;", parameters: [.string(tableName)])
    }
}

// MARK: - Tests

public extension SQLiteCloudCommand {
    // The TEST command is used for debugging purposes and can be used by developers while developing the SCSP for a new language.
    // By specifying a different test_name, the server will reply with different responses so you can test the parsing capabilities
    // of your new binding. Supported test_name are: STRING, STRING0, ZERO_STRING, ERROR, EXTERROR, INTEGER, FLOAT, BLOB, BLOB0,
    // ROWSET, ROWSET_CHUNK, JSON, NULL, COMMAND, ARRAY, ARRAY0.
    
    static let testCommand = SQLiteCloudCommand(query: "TEST COMMAND;")
    static let testNull = SQLiteCloudCommand(query: "TEST NULL;")
    static let testArray = SQLiteCloudCommand(query: "TEST ARRAY;")
    static let testArray0 = SQLiteCloudCommand(query: "TEST ARRAY0;")
    static let testJson = SQLiteCloudCommand(query: "TEST JSON;")
    static let testBlob = SQLiteCloudCommand(query: "TEST BLOB;")
    static let testBlob0 = SQLiteCloudCommand(query: "TEST BLOB0;")
    static let testError = SQLiteCloudCommand(query: "TEST ERROR;")
    static let testExtError = SQLiteCloudCommand(query: "TEST EXTERROR;")
    static let testInteger = SQLiteCloudCommand(query: "TEST INTEGER;")
    static let testFloat = SQLiteCloudCommand(query: "TEST FLOAT;")
    static let testString = SQLiteCloudCommand(query: "TEST STRING;")
    static let testString0 = SQLiteCloudCommand(query: "TEST STRING0;")
    static let testZeroString = SQLiteCloudCommand(query: "TEST ZERO_STRING;")
    static let testRowset = SQLiteCloudCommand(query: "TEST ROWSET;")
    static let testRowsetChunk = SQLiteCloudCommand(query: "TEST ROWSET_CHUNK;")
}

// MARK: - User

public extension SQLiteCloudCommand {
    /// The GET USER command returns the username of the currency-connected user.
    static let getUser = SQLiteCloudCommand(query: "GET USER;")
    
    /// The CREATE USER command adds a new user username with a specified password to the server.
    /// During user creation, you can also pass a comma-separated list of roles to apply to that user.
    /// The DATABASE and/or TABLE arguments can further restrict the which resources the user can access.
    ///
    /// - Parameters:
    ///   - username: The username.
    ///   - password: The user password.
    ///   - roles: A comma-separated list of roles.
    ///   - database: The database name.
    ///   - table: The table name.
    /// - Returns: An instance of `SQLiteCloudCommand`.
    static func createUser(username: String, password: String, roles: String? = nil, database: String? = nil, table: String? = nil) -> SQLiteCloudCommand {
        var query = "CREATE USER ? PASSWORD ?"
        
        var parameters: [SQLiteCloudValue] = [ .string(username), .string(password)]
        roles.map {
            query += " ROLE ?"
            parameters.append(.string($0))
        }
        
        database.map {
            query += " DATABASE ?"
            parameters.append(.string($0))
        }
        
        table.map {
            query += " TABLE ?"
            parameters.append(.string($0))
        }
        
        query += ";"
        return SQLiteCloudCommand(query: query, parameters: parameters)
    }
}

// MARK: - Channel

public extension SQLiteCloudCommand {
    /// The LIST CHANNELS command returns a list of previously created channels that can be used to 
    /// exchange messages. This command returns only channels created with the CREATE CHANNEL command.
    /// You can also subscribe to a table to receive all table-related events (INSERT, UPDATE, and DELETE).
    /// The LIST TABLES PUBSUB return a rowset compatible with the rowset returned by the LIST CHANNELS command.
    static let listChannels = SQLiteCloudCommand(query: "LIST CHANNELS;")
    
    /// The LISTEN command is used to start receiving notifications for a given channel. Nothing is done
    /// if the current connection is registered as a listener for this notification channel.
    ///
    /// - Parameter channel: The channel name.
    /// - Returns: An instance of `SQLiteCloudCommand`.
    static func listen(channel: String) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "LISTEN ?;", parameters: [.string(channel)])
    }
    
    /// The LISTEN command is used to start receiving notifications for a given table. Nothing is done
    /// if the current connection is registered as a listener for this notification channel.
    ///
    /// LISTENING to a table means you'll receive notification about all the write operations in that 
    /// table. In the case of TABLE, the channel_name can be *, which means you'll start receiving notifications
    /// from all the tables inside the current database.
    ///
    /// - Parameter table: The table name or * to listen all tables.
    /// - Returns: An instance of `SQLiteCloudCommand`.
    static func listen(table: String) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "LISTEN TABLE ?;", parameters: [.string(table)])
    }
    
    /// The CREATE CHANNEL command creates a new Pub/Sub environment channel. It is usually an error to attempt
    /// to create a new channel if another one exists with the same name. However, if the `ifNotExists` parameter is `true`
    /// and a channel of the same name already exists, the CREATE CHANNEL command has no effect (and no error message
    /// is returned). An error is still returned if the channel cannot be created for any other reason, even if
    /// the `ifNotExists` parameter is `true`.
    ///
    /// - Parameters:
    ///   - channel: The channel name to create.
    ///   - ifNotExists: Create channel only if not already exist.
    /// - Returns: An instance of `SQLiteCloudCommand`.
    static func create(channel: String, ifNotExists: Bool) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "CREATE CHANNEL ?\(ifNotExists ? " IF NOT EXISTS" : .empty);", parameters: [.string(channel)])
    }
    
    /// The NOTIFY command sends an optional payload (usually a string) to a specified channel name.
    /// If no payload is specified, then an empty notification is sent.
    ///
    /// - Parameters:
    ///   - channel: The channel on which to send the message.
    ///   - payload: The message payload, usually a string.
    /// - Returns: An instance of `SQLiteCloudCommand`.
    static func notify(channel: String, payload: String) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "NOTIFY ? '?'", parameters: [.string(channel), .string(payload)])
    }
    
    static func remove(channel: String) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "REMOVE CHANNEL ?", parameters: [.string(channel)])
    }
    
    static func unlisten(channel: String) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "UNLISTEN ?", parameters: [.string(channel)])
    }
    
    static func unlisten(table: String) -> SQLiteCloudCommand {
        SQLiteCloudCommand(query: "UNLISTEN ?", parameters: [.string(table)])
    }
    
    static func listen(channel: SQLiteCloudChannel) -> SQLiteCloudCommand {
        switch channel {
        case .name(let name):
            return .listen(channel: name)
            
        case .table(let name):
            return .listen(table: name)
            
        case .allTables:
            return .listen(table: "*")
        }
    }
    
    static func unlisten(channel: SQLiteCloudChannel) -> SQLiteCloudCommand {
        switch channel {
        case .name(let name):
            return .unlisten(channel: name)
            
        case .table(let name):
            return .unlisten(table: name)
            
        case .allTables:
            return .unlisten(table: "*")
        }
    }
}
