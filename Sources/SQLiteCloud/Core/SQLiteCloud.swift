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
import CSQCloud
import Darwin

/// An actor that interfaces with SQLite Cloud, providing methods for database
/// operations and real-time notifications.
///
/// SQLiteCloud is a set of functions that allow Swift programs to interact with 
/// the SQLite Cloud backend server, pass queries and SQL commands, and receive
/// the results of these queries.
///
/// In addition to standard SQLite statements, several other commands are supported,
/// and the SQLiteCloud APIs implement the SQLiteCloud Serialization Protocol.
///
/// To use this actor, create an instance of `SQLiteCloud` with the appropriate
/// configuration and call its methods.
///
/// Example usage:
/// ```swift
/// let config = SQLiteCloudConfig(...) // Initialize with your configuration
/// let sqliteCloud = SQLiteCloud(config: config)
/// ```
/// Note: This actor provides both synchronous and asynchronous methods for various
/// database operations.
///
/// - SeeAlso: `SQLiteCloudConfig` for configuring the SQLite Cloud connection.
/// - SeeAlso: `SQLiteCloudCommand` for representing SQL commands and queries.
/// - SeeAlso: `SQLiteCloudResult` for representing the result of database operations.
public final actor SQLiteCloud: SQLiteCloudProvider {
    /// The sqlcloud connection opaque pointer.
    ///
    /// This property represents an opaque pointer to the SQLite Cloud connection.
    /// It is used internally to manage the connection to the SQLite Cloud backend
    /// server. This connection is established when the `connect` method is called
    /// and is closed when the `disconnect` method is called.
    ///
    ///  - Note: Access to this property is private, and it should not be accessed 
    ///          directly from outside the `SQLiteCloud` actor. Instead, use the
    ///          provided methods like `connect` and `disconnect` to manage the
    ///          database connection.
    ///
    /// - SeeAlso: `SQLiteCloud.connect()` for establishing a connection to the SQLite Cloud server.
    /// - SeeAlso: `SQLiteCloud.disconnect()` for closing the active database connection.
    private var connection: OpaquePointer?
    
    /// An observation object for managing SQLite Cloud subscriptions.
    ///
    /// This property holds an instance of `Observation` specialized for
    /// `SQLiteCloudSubscription`. It is used to manage subscriptions to SQLite Cloud
    /// channels and allows for tracking and handling real-time notifications and
    /// updates. The `Observation` class provides mechanisms for adding and removing
    /// subscribers, as well as notifying subscribers when events occur.
    ///
    /// - Note: This property is used internally to manage subscriptions and should not
    ///         be accessed directly from outside the `SQLiteCloud` actor. To interact
    ///         with subscriptions, use the provided methods and APIs for managing
    ///         channels and subscriptions.
    ///
    /// - SeeAlso: `SQLiteCloud.listen(to:, callback:)` for subscribing to a SQLite Cloud channel.
    private var observation = Observation<SQLiteCloudSubscription>()
    
    /// Stores the count of subscribers for each SQLite Cloud channel.
    ///
    /// This property is a dictionary that associates each subscribed SQLite Cloud
    /// channel with the count of subscribers currently listening to that channel.
    /// It is used internally to keep track of the number of subscribers for each
    /// channel and ensure that channels are correctly managed.
    ///
    /// - Note: This property is used internally by the `SQLiteCloud` actor to track 
    ///         channel subscriptions, and it is not intended to be accessed directly
    ///         from outside the actor. To interact with channel subscriptions, use
    ///         the provided methods and APIs for managing channels and subscriptions.
    ///
    /// - SeeAlso: `SQLiteCloud.listen(to:, callback:)` for subscribing to a SQLite Cloud channel.
    private var channels: [SQLiteCloudChannel: Int] = [:]

    /// A property that holds the configuration for establishing a connection to the 
    /// SQLite Cloud server.
    ///
    /// This property defines various connection parameters such as the hostname,
    /// port, username, password, and other options required to connect to the
    /// SQLite Cloud server.
    ///
    /// - SeeAlso: `SQLiteCloudConfig` for details on the available configuration options.
    public let config: SQLiteCloudConfig
    
    /// A computed property that indicates whether logging is enabled for SQLite Cloud.
    ///
    /// This property allows you to check whether the SQLite Cloud logging system is 
    /// currently enabled or disabled. Logging can be a useful tool for debugging and
    /// monitoring the SQLite Cloud interactions.
    ///
    ///  - Returns: `true` if logging is enabled, `false` otherwise.
    public var isLoggingEnabled: Bool { SQLogger.instance.isLoggingEnabled }
    
    /// A property representing the connection status to SQLite Cloud.
    ///
    /// This property stores whether the client is currently connected to the
    /// SQLite Cloud server. It's set to `false` by default, indicating that the
    /// client is not connected upon initialization. The `private(set)` modifier
    /// restricts external modification of this property while allowing internal
    /// updates.
    public private(set) var isConnected = false
    
    /// Initializes a new instance of the `SQLiteCloud` actor with the provided 
    /// configuration.
    ///
    /// This initializer creates a new `SQLiteCloud` instance using the specified 
    /// configuration settings. The configuration includes details such as the
    /// hostname, port, username, password, and various connection options. Once
    /// initialized, you can use this instance to interact with SQLite Cloud by
    /// calling its methods.
    ///
    ///  - Parameter config: The SQLiteCloudConfig object containing connection 
    ///                      and configuration details such as hostname, port,
    ///                      username, password, and other options.
    public init(config: SQLiteCloudConfig) {
        self.config = config
    }
}

// MARK: - Private Methods

private extension SQLiteCloud {
    func getConnection() throws -> OpaquePointer {
        guard let connection else {
            throw SQLiteCloudError.connectionFailure(.invalidConnection)
        }
        
        return connection
    }
    
    func listener(conn: OpaquePointer?, result: OpaquePointer?) {
        guard let conn else { return }
        guard let result else { return }
        guard let liteResult = try? ResultParser.parse(result: result, connection: conn) else { return }
        guard case .json(let json) = liteResult else { return }
        guard let data = json.data(using: .utf8) else { return }
        
        do {
            let payload = try JSONDecoder().decode(SQLiteCloudPayload.self, from: data)
            let channel = payload.channel
            observation.apply(where: { $0.channel.name == channel }, value: payload)
            logDebug(category: "PUB/SUB", message: "✉️ Message received: \(payload)")
        } catch {
            logError(category: "PUB/SUB", message: "🚨 Message decoding error: \(error)")
        }
    }
    
    func exec(command: SQLiteCloudCommand) throws -> SQLiteCloudResult {
        // Checks if connection is open and valid.
        let conn = try getConnection()
        
        // If you pass the `query` parameter directly to the `SQCloudExec` function,
        // an EXC_BAD_ACCESS crash can occasionally occur. We first need to transform
        // a swift string into a C string (aka [CChar])
        let query = command.query
        let execCommand = query.cString(using: .utf8)
        
        // Execute sql query.
        let result: OpaquePointer?
        if command.parameters.isEmpty {
            result = SQCloudExec(conn, execCommand)
        } else {
            let num = command.parameters.count
            var types = command.parameters.map(\.sqlType)
            var len = command.parameters.map { UInt32($0.strlen) }
            let params = command.parameters.compactMap(\.stringValue)
            
            result = withArrayOfCStrings(params) { mutable in
                var values = mutable
                return SQCloudExecArray(conn, execCommand, &values, &len, &types, UInt32(num))
            }
        }
        
        // If the result is nil, there was an error either during the
        // connection (e.g. invalid credentials) or during the execution
        // of the query (e.g. database does not exist.)
        guard let result else {
            let error = SQLiteCloudError.handleError(connection: conn)
            logError(category: "COMMAND", message: "🚨 '\(query)' command failed: \(error)")
            throw error
        }
        
        // Before returning the result it is necessary to free the opaque pointer.
        defer { SQCloudResultFree(result) }
        logInfo(category: "COMMAND", message: "🚀 '\(query)' command executed successfully")
        
        // Try parsing the result. Parsing can throw several errors.
        return try ResultParser.parse(result: result, connection: conn)
    }
    
    func change(channel: SQLiteCloudChannel, counter: Int) async throws {
        channels[channel] = (channels[channel] ?? 0) + counter
        
        if channels[channel] == 0 {
            _ = try exec(command: .unlisten(channel: channel))
            logInfo(category: "PUB/SUB", message: "🙉 Unlisten channel '\(channel.name)'")
        }
    }
    
    func getBlobHandler(info: SQLiteCloudBlobInfo, rowId: Int, readWrite: Bool) throws -> OpaquePointer {
        // Checks if connection is open and valid.
        let conn = try getConnection()
        
        // Prepares parameters
        let schema = info.schema?.cString(using: .utf8)
        let table = info.table.cString(using: .utf8)
        let column = info.column.cString(using: .utf8)
        
        // The SQCloudBlobOpen interface opens a BLOB for incremental I/O. This interfaces opens a
        // handle to the BLOB located in row rowid, column colname, table tablename in database dbname;
        // in other words, the same BLOB that would be selected by:
        // SELECT colname FROM dbname.tablename WHERE rowid = rowid;
        let handler = SQCloudBlobOpen(conn, schema, table, column, Int64(rowId), readWrite)
        guard let handler else {
            let error = SQLiteCloudError.handleError(connection: conn)
            logError(category: "BLOB", message: "🚨 Blob Open failed: \(error)")
            throw error
        }
        
        return handler
    }
    
    func reopen(handler: OpaquePointer, atRowId rowId: Int, ifNecessary condition: Bool) throws {
        // If there is more than one row we should not close and reopen the blob handler, but instead
        // we must invoke the `SQCloudBlobReOpen` function to move the handler to a different row.
        guard condition else { return }
        
        // Checks if connection is open and valid.
        let conn = try getConnection()
        
        // This function is used to move an existing BLOB handle so that it points to a different
        // row of the same database table. The new row is identified by the rowid value passed as
        // the second argument. Only the row can be changed. The database, table and column on
        // which the blob handle is open remain the same.
        let result = SQCloudBlobReOpen(handler, Int64(rowId))
        
        // Checks if SQCloudBlobReOpen failed.
        if SQCloudIsError(conn) {
            let error = SQLiteCloudError.handleError(connection: conn)
            logError(category: "BLOB", message: "🚨 ReOpen blob handler failed: \(error)")
            throw error
        }
        
        if result == false {
            throw SQLiteCloudError.taskError(.invalidNumberOfRows)
        }
    }
}

// MARK: - Configurations

public extension SQLiteCloud {
    /// Set the logging status for the `SQLiteCloud` operations.
    ///
    /// This method allows you to enable or disable logging for `SQLiteCloud` operations performed
    /// by the `SQLogger` instance. When logging is enabled, database activity such as queries and
    /// updates will be recorded, which can be useful for debugging and monitoring purposes.
    ///
    /// - Parameters:
    ///    - isLoggingEnabled: A boolean value indicating whether logging should be enabled (true) 
    ///                        or disabled (false).
    ///
    /// Example usage:
    ///
    /// ```swift
    /// await sqliteCloud.set(isLoggingEnabled: true) // Enable logging
    /// await sqliteCloud.set(isLoggingEnabled: false) // Disable logging
    /// ```
    func set(isLoggingEnabled: Bool) async {
        SQLogger.instance.isLoggingEnabled = isLoggingEnabled
    }
}

// MARK: - Connection API

public extension SQLiteCloud {
    /// The `connect` method establishes a connection to a database node using the specified 
    /// configuration. It creates a new SQCloudConnection object, configures a callback function
    /// to handle Pub/Sub notifications, and sets up the connection for use.
    ///
    /// It creates a new SQCloudConnection handler, configures a callback function to handle 
    /// Pub/Sub notifications, and sets up the connection for use.
    ///
    ///  Example usage:
    ///  ```swift
    ///  do {
    ///     let sqliteCloud = SQLiteCLoud(config: ...)
    ///     try await sqliteCloud.connect()
    ///     // Connection successful, perform database operations here
    ///  } catch {
    ///     print("Error: \(error)")
    ///  }
    ///  ```
    ///
    /// - Throws: `SQLiteCloudError`: If an error occurs during the connection process, this
    ///            method throws an `SQLiteCloudError.connectionFailure` with context details
    ///            about the error.
    func connect() async throws {
        // Creates an instance of the SQCloudConfig based upon an instance of SQLiteCloudConfig.
        let port = config.port.number
        let hostname = config.hostname
        var sqConfig = config.sqConfig
        
        // Initiate a new connection to a database node specified by hostname and port. This function
        // will always return a non-null object pointer, unless there is too little memory even to
        // allocate the SQCloudConnection object.
        logDebug(category: "CONNECTION", message: "📡 Connecting to \(config.connectionString)...")
        let conn = SQCloudConnect(hostname, port, &sqConfig)
        
        // Check if there was an error during the connection.
        // If so the `handleError` function creates the swift error to throw.
        guard SQCloudIsError(conn) == false else {
            let error = SQLiteCloudError.handleError(connection: conn)
            logError(category: "CONNECTION", message: "🚨 Connection to \(config.connectionString) failed: \(error)")
            throw error
        }
        
        // The callback used in the C method is not a Swift closure so it cannot capture the scope
        // in which it is created. For this reason we need to wrap the "self" instance in a row
        // pointer and pass it as a parameter to the C function.
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let callback: SQCloudPubSubCB = { conn, result, selfPointer in
            Task {
                guard let selfPointer else { return }
                let mySelf = Unmanaged<SQLiteCloud>.fromOpaque(selfPointer).takeUnretainedValue()
                await mySelf.listener(conn: conn, result: result)
            }
        }
        
        // By using SQCloudSetPubSubCallback, we can set a callback function that will be automatically
        // triggered each time a notification is received. It's possible to call this function multiple
        // times, but it will be executed only once. The callback function is executed in an independent
        // secondary thread, which allows the main thread to perform other commands without interruption.
        SQCloudSetPubSubCallback(conn, callback, selfPointer)
        
        // When Pub/Sub is activated (after calling SQCloudSetPubSubCallback) there are two sockets
        // associated to the SQCloudConnection connection. The SQCloudSetPubSubOnly function closes
        // the main socket, leaving the pub/sub socket opened and ready to receive incoming notifications
        // from subscripted channels and tables.
        if config.isReadonlyConnection {
            // close main socket
            let result = SQCloudSetPubSubOnly(conn)
            
            // An OK result is succesfully executed, otherwise an error.
            if SQCloudResultIsError(result) {
                let error = SQLiteCloudError.handleError(connection: conn)
                logError(category: "CONNECTION", message: "🚨 Error during SQCloudSetPubSubOnly: \(error)")
                throw error
            }
        }
        
        // Sets new connection to the local properties
        connection = conn
        isConnected = true
        logDebug(category: "CONNECTION", message: "📡 Connection to \(config.connectionString) successful")
    }
    
    /// Disconnects from the database server.
    ///
    /// This method closes the active database connection, releasing any associated resources, 
    /// and resets the connection properties to indicate that the connection is closed.
    ///
    /// - Throws: `SQLiteCloudError`: If an error if the connection cannot be closed or if 
    ///           the connection is already closed.
    ///
    /// - Important: Before calling this method, ensure that you have an open and valid database 
    ///              connection by using the `connect()` method. If the connection is not open or
    ///              is invalid, this method will throw an error.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// do {
    ///     let sqliteCloud = SQLiteCLoud(config: ...)
    ///     try await sqliteCloud.connect()
    ///
    ///     // perform database operations
    ///
    ///     try await disconnect()
    ///     // Connection successfully closed
    /// } catch {
    ///     print("Error: \(error)")
    /// }
    /// ```
    func disconnect() async throws {
        // Checks if connection is open and valid.
        let conn = try getConnection()
        
        // Closes the connection to the server.
        // Also frees memory used by the SQCloudConnection object.
        SQCloudDisconnect(conn)
        
        // Reset connection properties
        isConnected = false
        connection = nil
    }
    
    /// Get the unique client UUID associated with the current connection.
    ///
    /// This method retrieves the unique client UUID value for the active database connection.
    /// The UUID serves as a client identifier and can be used for various purposes, such as 
    /// tracking client-specific data.
    ///
    /// - Returns: A `UUID` instance representing the client's unique identifier.
    ///
    /// - Throws: `SQLiteCloudError`: if an error if the connection cannot be established, or
    ///           if the UUID retrieved from the database is invalid or nil.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// do {
    ///     let clientUUID = try await sqliteCloud.getClientUUID()
    ///     print("Client UUID: \(clientUUID)")
    /// } catch {
    ///     print("Error: \(error)")
    /// }
    /// ```
    ///
    /// - Note: The UUID is typically represented as a string in the format 
    ///         "E621E1F8-C36C-495A-93FC-0C247A3E6E5F". This method retrieves it from the
    ///          database as a C-style string and converts it into a Swift UUID instance.
    func getClientUUID() async throws -> UUID {
        // Checks if connection is open and valid.
        let conn = try getConnection()
        
        // The SQCloudUUID function returns the unique client UUID value.
        // If the UUID is nil, an error has probably occurred.
        guard let value = SQCloudUUID(conn) else {
            throw SQLiteCloudError.connectionFailure(.invalidUUID)
        }
        
        // Transforms the uuid in the form of UnsafePointer<CChar> into a
        // swift string and then into an instance of the native type UUID.
        // the string must have the format “E621E1F8-C36C-495A-93FC-0C247A3E6E5F”.
        let uuidString = String(cString: value)
        guard let uuid = UUID(uuidString: uuidString) else {
            throw SQLiteCloudError.connectionFailure(.invalidUUID)
        }
        
        return uuid
    }
}

// MARK: - Execute API

public extension SQLiteCloud {
    /// Execute a SQL command on the SQLite Cloud database.
    ///
    /// This method allows to execute SQL commands (queries or updates) on the SQLite Cloud database
    /// associated with the active connection. It takes a `SQLiteCloudCommand` object as input,
    /// which includes the SQL query string and any parameters if needed.
    ///
    /// - Parameters:
    ///   - command: A `SQLiteCloudCommand` object containing the SQL command and optional parameters.
    ///
    /// - Returns: A `SQLiteCloudResult` object containing the result of the SQL command execution.
    ///
    /// - Throws: `SQLiteCloudError.connectionFailure` if the connection cannot be established,
    ///
    /// - Throws: `SQLiteCloudError.executionFailed` if there is an issue with the SQL command or
    ///           parameters, or if an error occurs during the execution of the query.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// do {
    ///     let sql = "SELECT * FROM users WHERE id = ?"
    ///     let command = SQLiteCloudCommand(query: sql, parameters: [.integer(42)])
    ///     let result = try sqliteCloud.execute(command: command)
    ///     // Process the result
    /// } catch {
    ///     print("Error: \(error)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - command: An instance of the `SQLiteCloudCommand` type that represents the SQL command to execute.
    /// - Returns: A instance of `SQLiteCloudResult`.
    /// - Throws: `SQLiteCloudError.connectionFailure` if the connection is not invalid or a network error has occurred.
    /// - Throws: `SQLiteCloudError.executionFailed` if the query is not valid.
    ///
    func execute(command: SQLiteCloudCommand) async throws -> SQLiteCloudResult {
        try exec(command: command)
    }
    
    /// Execute a SQL query on the SQLite Cloud database.
    ///
    /// This method allows to execute SQL commands (queries or updates) on the SQLite Cloud database
    /// associated with the active connection. It takes a generic SQL statement as input.
    ///
    /// - Parameters:
    ///   - query: A generic SQL statement to execute.
    ///
    /// - Returns: A `SQLiteCloudResult` object containing the result of the SQL command execution.
    ///
    /// - Throws: `SQLiteCloudError.connectionFailure` if the connection cannot be established,
    ///
    /// - Throws: `SQLiteCloudError.executionFailed` if there is an issue with the SQL command or
    ///           parameters, or if an error occurs during the execution of the query.
    ///
    /// - Important: Please use `execute` with `SQLiteCloudCommand` if you have parameters in SQL statement.
    ///              This is important for safely binding values into the query and preventing SQL injection.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// do {
    ///     let sql = "SELECT * FROM users"
    ///     let result = try sqliteCloud.execute(query: sql)
    ///     // Process the result
    /// } catch {
    ///     print("Error: \(error)")
    /// }
    /// ```
    func execute(query: String) async throws -> SQLiteCloudResult {
        try exec(command: SQLiteCloudCommand(query: query))
    }
    
    /// Execute a SQL query with optional parameters on the SQLite Cloud database.
    ///
    /// This method allows you to execute a SQL query on the SQLite Cloud database with an optional
    /// set of parameters for safe and efficient data retrieval. Using `SQLiteCloudValue` as
    /// parameters is important for safely binding values into the query and preventing SQL injection.
    ///
    /// - Parameters:
    ///   - query: A string containing the SQL query to execute.
    ///   - parameters: An array of `SQLiteCloudValue` objects representing optional parameters to
    ///                 bind into the query.
    /// - Returns: A `SQLiteCloudResult` object containing the result of the SQL query execution.
    ///
    /// - Throws: `SQLiteCloudError.connectionFailure` if the connection cannot be established,
    ///
    /// - Throws: `SQLiteCloudError.executionFailed` if there is an issue with the SQL command or
    ///           parameters, or if an error occurs during the execution of the query.
    ///
    /// Example usage:
    ///
    /// ```swift
    ///  do {
    ///     let sql = "SELECT * FROM users WHERE id = ?"
    ///     let parameters: [SQLiteCloudValue] = [.integer(42)]
    ///     let result = try await sqliteCloud.execute(query: sql, parameters: parameters)
    ///     // Process the query result
    /// } catch {
    ///     print("Error: \(error)")
    /// }
    /// ```
    func execute(query: String, parameters: [SQLiteCloudValue]) async throws -> SQLiteCloudResult {
        try exec(command: SQLiteCloudCommand(query: query, parameters: parameters))
    }
    
    /// Execute a SQL query with optional parameters on the SQLite Cloud database.
    ///
    /// This method allows you to execute a SQL query on the SQLite Cloud database with an optional
    /// set of parameters for safe and efficient data retrieval. Using `SQLiteCloudValue` as
    /// parameters is important for safely binding values into the query and preventing SQL injection.
    ///
    /// - Parameters:
    ///   - query: A string containing the SQL query to execute.
    ///   - parameters: An array of `SQLiteCloudValue` objects representing optional parameters to
    ///                 bind into the query.
    ///
    /// - Returns: A `SQLiteCloudResult` object containing the result of the SQL query execution.
    ///
    /// - Throws: `SQLiteCloudError.connectionFailure` if the connection cannot be established,
    ///
    /// - Throws: `SQLiteCloudError.executionFailed` if there is an issue with the SQL command or
    ///           parameters, or if an error occurs during the execution of the query.
    ///
    /// Example usage:
    ///
    /// ```swift
    ///  do {
    ///     let sql = "SELECT * FROM users WHERE id = ?"
    ///     let parameters: [SQLiteCloudValue] = [.integer(42)]
    ///     let result = try await sqliteCloud.execute(query: sql, parameters: parameters)
    ///     // Process the query result
    /// } catch {
    ///     print("Error: \(error)")
    /// }
    /// ```
    func execute(query: String, _ parameters: SQLiteCloudValue...) async throws -> SQLiteCloudResult {
        try exec(command: SQLiteCloudCommand(query: query, parameters: parameters))
    }
}

// MARK: - Pub/Sub API

public extension SQLiteCloud {
    /// Create a Pub/Sub channel in the SQLite Cloud database.
    ///
    /// This method allows you to create a Pub/Sub channel within the SQLite Cloud database.
    /// A Pub/Sub channel is used for publishing and subscribing to real-time notifications
    /// and updates.
    ///
    /// - Parameters:
    ///   - channel: A string specifying the name of the Pub/Sub channel to create.
    ///   - ifNotExists: A boolean value indicating whether to create the channel if it does not
    ///                  already exist (default is true). If set to true and the channel already
    ///                  exists, the method will not throw an error.
    ///
    /// - Returns: A `SQLiteCloudResult` object containing the result of the channel creation.
    ///
    /// - Throws: `SQLiteCloudError.connectionFailure` if the connection is not invalid or a
    ///            network error has occurred.
    ///
    /// - Throws: `SQLiteCloudError.executionFailed` if the channel query is not valid.
    ///
    ///  Example usage:
    /// ```swift
    /// do {
    ///     let channelName = "myChannel"
    ///     let result = try await sqliteCloud.create(channel: channelName)
    ///     // Channel created successfully
    /// } catch {
    ///     print("Error: \(error)")
    /// }
    /// ```
    func create(channel: String, ifNotExists: Bool = true) async throws -> SQLiteCloudResult {
        try exec(command: .create(channel: channel, ifNotExists: ifNotExists))
    }
    
    /// Send a notification message to a Pub/Sub channel in the SQLite Cloud database.
    ///
    /// This method allows you to send a notification message to a specific Pub/Sub channel
    /// within the SQLite Cloud database. The message can carry a payload conforming to the
    /// `Payloadable` protocol, which must be Codable and Sendable. If the specified channel
    /// does not exist and `createChannelIfNotExist` is set to true in the message, the channel
    /// will be created before sending the message.
    ///
    /// - Parameters:
    ///     - message: A `SQLiteCloudMessage` object containing the channel name, payload, and optional configuration.
    ///
    /// - Returns: A `SQLiteCloudResult` object containing the result of the notification message operation.
    ///
    /// - Throws: `SQLiteCloudError.connectionFailure` if the connection is not invalid or a
    ///            network error has occurred.
    ///
    /// - Throws: `SQLiteCloudError.executionFailed` if the channel query is not valid.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// struct MyPayload: Codable, Sendable {
    ///     let content: String
    /// }
    ///
    /// let mypayload = MyPayload(content: "Hello, World!")
    /// let message = SQLiteCloudMessage(channel: "myChannel", payload: mypayload, createChannelIfNotExist: true)
    ///
    /// do {
    ///     let result = try await sqliteCloud.notify(message: message)
    ///     // Message sent successfully
    /// } catch {
    ///     print("Error: \(error)")
    /// }
    /// ```
    func notify<P: Payloadable>(message: SQLiteCloudMessage<P>) async throws -> SQLiteCloudResult {
        if message.createChannelIfNotExist {
            _ = try exec(command: .create(channel: message.channel, ifNotExists: true))
        }
        
        let encoder = JSONEncoder()
        let encode = try encoder.encode(message.payload)
        let stringify = String(data: encode, encoding: .utf8) ?? .empty
        
        return try exec(command: .notify(channel: message.channel, payload: stringify))
    }
    
    /// Listen for notifications on a specified SQLite Cloud channel.
    ///
    /// This method allows you to listen for real-time notifications and updates on a specific 
    /// SQLite Cloud channel. When a notification is received on the channel, the provided
    /// callback function is invoked. You can use this feature for building real-time data
    /// synchronization and event-driven applications.
    ///
    /// Listening to a table means you'll receive notification about all the write operations in
    /// that table. In the case of table, the table name can be *, which means you'll start
    /// receiving notifications from all the tables inside the current database.
    ///
    /// - Parameters:
    ///   - channel: A `SQLiteCloudChannel` object representing the channel to listen to.
    ///   - callback: A callback function that is called when a notification is received on the
    ///               specified channel. The callback takes a `SQLiteCloudNotification` object as
    ///               its parameter.
    ///
    /// - Returns: A `Disposable` object that allows you to unsubscribe from the channel when you
    ///            no longer wish to receive notifications.
    ///
    /// - Throws: `SQLiteCloudError.connectionFailure` if the connection is not invalid or a network
    ///            error has occurred.
    ///
    /// - Throws: `SQLiteCloudError.executionFailed` if the channel query is not valid.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// let myChannel = SQLiteCloudChannel.name("myChannel")
    /// self.disposable = try await sqliteCloud.listen(to: myChannel) { payload in
    ///     // Handle the received payload
    ///     print("Received payload: \(payload)")
    /// }
    ///
    /// // Later, when you want to stop listening to the channel:
    /// self.disposable = nil
    /// ```
    /// - Note: The provided callback function is executed whenever a notification is received
    ///         on the specified channel. You can use the returned Disposable object to unsubscribe
    ///         from the channel when you no longer wish to receive notifications, freeing up resources.
    func listen(to channel: SQLiteCloudChannel, callback: @escaping NotificationHandler) async throws -> Disposable {
        // Starts listening notifications for a given channel/table.
        _ = try exec(command: .listen(channel: channel))
         
        channels[channel] = (channels[channel] ?? 0) + 1
        
        let onUnsubscribe: Callback<SQLiteCloudChannel> = { [weak self ] channel in
            Task { [weak self] in
                guard let self else { return }
                try await self.change(channel: channel, counter: -1)
            }
        }
        
        let subscription = SQLiteCloudSubscription(channel: channel,
                                                   callback: callback,
                                                   onUnsubscribe: onUnsubscribe)
        
        let observer = observation.add(observer: subscription)
        logInfo(category: "PUB/SUB", message: "🎧 Listening to channel '\(channel.name)'")
        return observer
    }
}

// MARK: - Upload/Download database

public extension SQLiteCloud {
    /// Uploads a database file to the SQLite Cloud server with progress tracking.
    /// 
    /// This method allows you to upload a database file to the SQLite Cloud server.
    /// The upload process is asynchronous and provides progress tracking through
    /// the `progressHandler` callback.
    ///
    /// - Parameters:
    ///   - database: The `SQLiteCloudUploadDatabase` object representing the database file
    ///               to upload, containing the URL, database name, and optional encryption key.
    ///   - progressHandler: A closure that receives progress updates during the upload process.
    ///                      The closure takes two parameters: `completedBytes` (the number of
    ///                      bytes uploaded) and `totalBytes` (the total size of the database file).
    /// - Throws:
    ///    An error of type `SQLiteCloudError` if the upload process fails.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// let databaseURL = URL(fileURLWithPath: "/path/to/your/database.db")
    /// let uploadDatabase = SQLiteCloudUploadDatabase(url: databaseURL, databaseName: "mydb")
    /// try sqliteCloud.upload(databse: uploadDatabase) { progress in
    ///     print("Progress: \(progress * 100)%")
    /// }
    /// ```
    ///
    /// - Note: The progressHandler closure is called periodically during the upload process,
    ///         allowing you to track the progress of the upload.
    func upload(database: SQLiteCloudUploadDatabase, progressHandler: @escaping ProgressHandler) async throws {
        // Checks if connection is open and valid.
        let conn = try getConnection()

        // Create an upload helper that manage the data stream and the progress of the upload.
        let dataHandler = try UploadHelper(url: database.url, progressHandler: progressHandler)
        let xData = UnsafeMutableRawPointer(Unmanaged.passRetained(dataHandler).toOpaque())

        logDebug(category: "UPLOAD", message: "🔼 Start upload database: \(database.name), from: \(database.url.absoluteString)")

        // Get the operation result from the C method passing the Upload Helper to manage the 
        // data stream and progress.
        let success = SQCloudUploadDatabase(conn,
                                            database.name,
                                            database.encryptionKey,
                                            xData,
                                            Int64(dataHandler.fileSize)) { xData, buffer, blen, ntot, nprogress in
            guard let xData else { return -1 }

            let dataHandler = Unmanaged<UploadHelper>.fromOpaque(xData).takeUnretainedValue()

            let result = UploadHelper.result(dataHandler: dataHandler,
                                             buffer: buffer,
                                             bufferLength: blen,
                                             totalLength: ntot,
                                             previousProgress: nprogress)

            if result.completed {
                Unmanaged<UploadHelper>.fromOpaque(xData).release()
            }

            return result.result
        }

        if success == false {
            let error = SQLiteCloudError.handleError(connection: conn)
            logError(category: "UPLOAD", message: "🚨 Database upload failed: \(error)")
            throw error
        }
         
        logDebug(category: "UPLOAD", message: "✅ Database upload succesfully")
    }

    /// Downloads a database from SQLite Cloud.
    ///
    /// This method asynchronously downloads a database from SQLite Cloud. It first checks if
    /// the connection to SQLite Cloud is open and valid. If the connection is valid, it
    /// proceeds with the download operation.
    ///
    /// - Parameters:
    ///    - database: A `SQLiteCloudDownloadDatabase` instance specifying the name of the database to download.
    ///    - progressHandler: A closure that receives progress updates during the download.
    ///
    /// - Throws:
    ///    An error of type `SQLiteCloudError` if the download process fails.
    ///
    /// - Returns: A URL to the downloaded database file.
    ///
    /// - Note: temporary files are created during the download process and should be cleaned up 
    ///         by the caller when no longer needed.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// let databaseToDownload = SQLiteCloudDownloadDatabase(name: "myDatabase")
    /// let downloadedDatabaseURL = try await sqliteCloud.download(database: databaseToDownload) { progress in
    ///     // Handle download progress updates
    /// }
    /// ```
    func download(database: SQLiteCloudDownloadDatabase, progressHandler: @escaping ProgressHandler) async throws -> URL {
        // Checks if connection is open and valid.
        let conn = try getConnection()

        // Create a download helper that manage the data stream and the progress of the download.
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        guard let dataHandler = DownloadHelper(filePath: url.path, progressHandler: progressHandler) else {
            logError(category: "DOWNLOAD", message: "🚨 Cannot create output file")
            throw SQLiteCloudError.taskError(.cannotCreateOutputFile)
        }
        let xData = UnsafeMutableRawPointer(Unmanaged.passRetained(dataHandler).toOpaque())

        logDebug(category: "DOWNLOAD", message: "🔽 Start download database: \(database.name)")

        let success = SQCloudDownloadDatabase(conn, database.name, xData) { xData, buffer, blen, ntot, nprogress in
            guard let xData, let buffer else { return -1 }

            let dataHandler = Unmanaged<DownloadHelper>.fromOpaque(xData).takeUnretainedValue()
            
            let result = DownloadHelper.result(dataHandler: dataHandler,
                                               buffer: buffer,
                                               bufferLength: blen,
                                               totalLength: ntot,
                                               previousProgress: nprogress)

            if result.completed {
                Unmanaged<DownloadHelper>.fromOpaque(xData).release()
            }

            return result.result
        }

        if success {
            return url
        } else {
            let error = SQLiteCloudError.handleError(connection: conn)
            logError(category: "DOWNLOAD", message: "🚨 Database download failed: \(error)")
            throw error
        }
    }
}

// MARK: - Blob API

public extension SQLiteCloud {
    /// Retrieve the size in bytes of one or more BLOB (Binary Large Object) fields in the
    /// SQLite Cloud database.
    ///
    /// This method allows you to retrieve the size in bytes of BLOB fields for one or more rows
    /// specified by their unique row IDs. The result is an array of `Int32` values, each representing
    /// the size in bytes of a BLOB field for a corresponding row ID.
    ///
    /// - Parameters:
    ///   - blob: A `SQLiteCloudBlobRead` object containing information about the BLOB field and the 
    ///          row IDs to retrieve the size for.
    ///
    /// - Returns: An array of `Int32` values, each representing the size in bytes of a BLOB field 
    ///            for a corresponding row ID.
    ///
    /// - Throws: `SQLiteCloudError.connectionFailure` if the connection is not invalid or a
    ///            network error has occurred.
    ///
    /// - Throws: `SQLiteCloudError.taskError` if the blob read failed.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// let blobInfo = SQLiteCloudBlobInfo(schema: "my_schema", table: "my_table", column: "my_blob_column")
    /// let rowIds = [1, 2, 3] // Row IDs to retrieve BLOB sizes
    /// let blobRead = SQLiteCloudBlobRead(info: blobInfo, rowIds: rowIds)
    /// let blobSizes = try await sqliteCloud.sizeInBytes(blob: blobRead)
    /// ```
    func sizeInBytes(blob: SQLiteCloudBlobRead) async throws -> [Int32] {
        // Checks if connection is open and valid.
        _ = try getConnection()
        
        // There must be at least one row.
        guard let firstRow = blob.rows.first else {
            throw SQLiteCloudError.taskError(.invalidNumberOfRows)
        }
        
        // Open readonly blob handler.
        let handler = try getBlobHandler(info: blob.info, rowId: firstRow.rowId, readWrite: false)
        defer { SQCloudBlobClose(handler) }
        
        let sizes = try blob.rows.enumerated().map { index, row in
            // If there is more than one row we should not close the current blob handler, but instead
            // we must invoke the `SQCloudBlobReOpen` function to move the handler to a different row.
            try reopen(handler: handler, atRowId: row.rowId, ifNecessary: index > 0)
            
            // This function returns the size in bytes of the BLOB accessible via the successfully
            // opened BLOB handle in its only argument. The incremental blob I/O routines can only
            // read or overwriting existing blob content; they cannot change the size of a blob.
            return SQCloudBlobBytes(handler)
        }
        
        return sizes
    }
    
    /// Read BLOB (Binary Large Object) data from the SQLite Cloud database.
    ///
    /// This method allows you to read BLOB data from the SQLite Cloud database. It reads BLOB
    /// data for one or more rows specified by their unique row IDs and returns the BLOB data
    /// as an array of `SQLiteCloudBlobReadResult` objects. The `progressHandler` callback
    /// allows you to track the progress of reading the BLOB data.
    ///
    ///  - Parameters:
    ///    - blob: A `SQLiteCloudBlobRead` object containing information about the BLOB field 
    ///            and the row IDs to read.
    ///    - progressHandler: An optional callback to track the progress of the BLOB data reading. 
    ///                       It is called with a progress value between 0.0 and 1.0 as the read
    ///                       operation progresses.
    ///
    ///  - Returns: An array of `Data` objects, each containing the BLOB data for a corresponding 
    ///             row ID.
    ///
    /// - Throws: `SQLiteCloudError.connectionFailure` if the connection is not invalid or a
    ///            network error has occurred.
    ///
    /// - Throws: `SQLiteCloudError.taskError` if the blob read failed.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// let blobInfo = SQLiteCloudBlobInfo(schema: "my_schema", table: "my_table", column: "my_blob_column")
    /// let rowIds = [1, 2, 3] // Row IDs to read BLOB data
    /// let blobRead = SQLiteCloudBlobRead(info: blobInfo, rowIds: rowIds)
    /// let blobData = try await sqliteCloud.read(blob: blobRead) { progress in
    ///     print("Progress: \(progress * 100)%")
    /// }
    /// ```
    func read(blob: SQLiteCloudBlobRead, progressHandler: ProgressHandler? = nil) async throws -> [SQLiteCloudBlobReadResult] {
        // Checks if connection is open and valid.
        let conn = try getConnection()
        
        // There must be at least one row.
        guard let firstRow = blob.rows.first else {
            throw SQLiteCloudError.taskError(.invalidNumberOfRows)
        }
        
        // Get blob handler
        let handler = try getBlobHandler(info: blob.info, rowId: firstRow.rowId, readWrite: false)
        defer { SQCloudBlobClose(handler) }
        
        // reader
        let reader = SQLiteCloudBlobReader(blobSizeThreshold: blob.blobSizeThreshold,
                                           blobChunkHandler: blob.blobChunkHandler)
                
        let result = try blob.rows.enumerated().map { index, row in
            // If there is more than one row we should not close the current blob handler, but instead
            // we must invoke the `SQCloudBlobReOpen` function to move the handler to a different row.
            try reopen(handler: handler, atRowId: row.rowId, ifNecessary: index > 0)
            
            let internalProgress: ProgressHandler = { prog in
                let total = blob.rows.count
                let totalProgress = (prog + Double(index)) / Double(total)
                progressHandler?(totalProgress)
            }
            
            let totalSize = SQCloudBlobBytes(handler)
            let result = try reader.read(row: row, totalSize: totalSize, progressHandler: internalProgress) { rowBuffer, bufferSize, offset in
                // The SQCloudBlobRead function is used to read data from an open BLOB handle into a
                // caller-supplied buffer. blen bytes of data are copied into buffer from the open
                // BLOB, starting at offset.
                let value = SQCloudBlobRead(handler, rowBuffer, bufferSize, offset)
                
                // Checks if reading is failed.
                if SQCloudIsError(conn) {
                    let error = SQLiteCloudError.handleError(connection: conn)
                    logError(category: "BLOB", message: "🚨 Blob reading failed: \(error)")
                    throw error
                }
                
                if value < 0 {
                    let error = SQLiteCloudError.taskError(.invalidBlobSizeRead)
                    logError(category: "BLOB", message: "🚨 Blob reading failed: \(error)")
                    throw error
                }
            }
            
            // log blob reading
            logDebug(category: "BLOB", message: "🗃️ Blob reading successful - rowId: \(row.rowId) - bytes: \(totalSize)")
            
            return result
        }
            
        // return data
        return result
    }
    
    /// Update a SQLite Cloud BLOB data field with new content.
    ///
    /// This method allows you to update a BLOB (Binary Large Object) data field in the 
    /// SQLite Cloud database with new content. You can use it to replace the existing BLOB
    /// data with new binary data, making it suitable for scenarios like image or file storage.
    /// The `automaticallyIncreasesBlobSize` property controls whether the method should
    /// automatically expand the BLOB field if the new data exceeds the current size.
    ///
    /// - Parameters:
    ///    - blob: A `SQLiteCloudBlobWrite` object containing information about the BLOB field 
    ///            and the new data to be written.
    ///    - progressHandler: An optional callback to track the progress of the BLOB data writing.
    ///                       It is called with a progress value between 0.0 and 1.0 as the write
    ///                       operation progresses.
    ///
    /// - Throws: `SQLiteCloudError.connectionFailure` if the connection is not invalid or a
    ///            network error has occurred.
    ///
    /// - Throws: `SQLiteCloudError.taskError` if the blob upload failed.
    ///
    ///  Example usage:
    ///
    ///  ```swift
    ///  let blobInfo = SQLiteCloudBlobInfo(schema: "my_schema", table: "my_table", column: "my_blob_column")
    ///  let data = Data([0x01, 0x02, 0x03]) // Replace BLOB data with new binary data
    ///  let blobWrite = SQLiteCloudBlobWrite(info: blobInfo, rows: [SQLiteCloudBlobWrite.Row(rowId: 1, dataSource: .data(data))])
    ///  try await sqliteCloud.update(blob: blobWrite) { progress in
    ///      print("Progress: \(progress * 100)%")
    ///  }
    ///  ```
    func update(blob: SQLiteCloudBlobWrite, progressHandler: ProgressHandler? = nil) async throws {
        // Checks if connection is open and valid.
        let conn = try getConnection()

        // There must be at least one row.
        guard let firstRowId = blob.rows.first?.rowId else {
            throw SQLiteCloudError.taskError(.invalidNumberOfRows)
        }
        
        // Open writing blob handler.
        let handler = try getBlobHandler(info: blob.info, rowId: firstRowId, readWrite: true)
        defer { SQCloudBlobClose(handler) }
        
        // writer
        let writer = SQLiteCloudBlobWriter(blobSizeThreshold: blob.blobSizeThreshold,
                                           blobChunkHandler: blob.blobChunkHandler)
                
        // It loops all the rows that need to be updated.
        try blob.rows.enumerated().forEach { index, row in
            // If there is more than one row we should not close the current blob handler, but instead
            // we must invoke the `SQCloudBlobReOpen` function to move the handler to a different row.
            try reopen(handler: handler, atRowId: row.rowId, ifNecessary: index > 0)
            
            // We need to check whether the blob field is large enough to store the entirely data.
            // If it is not large enough we need to "expand" the column via a sql query.
            let currentLen = SQCloudBlobBytes(handler)
            let dataBytesCount = try row.dataSource.bytesCount()
            if currentLen < dataBytesCount && blob.automaticallyIncreasesBlobSize {
                let info = blob.info
                _ = try exec(command: .expandBlob(table: info.table, column: info.column, rowId: row.rowId, size: dataBytesCount))
                
                // After increasing the blob size, it is necessary to reopen the handler in order
                // to acknowledge the change made.
                SQCloudBlobReOpen(handler, Int64(row.rowId))
            }
            
            let internalProgress: ProgressHandler = { prog in
                let total = blob.rows.count
                let totalProgress = (prog + Double(index)) / Double(total)
                progressHandler?(totalProgress)
            }
            
            // The SQCloudBlobWrite function is used to write data into an open BLOB handle from a
            // caller-supplied buffer. blen bytes of data are copied from the buffer into the open
            // BLOB, starting at offset.)
            try writer.writeBlob(row: row, progressHandler: internalProgress) { rawPointer, len, offset in
                let result = SQCloudBlobWrite(handler, rawPointer, len, offset)
                
                if result < 1 {
                    let error = SQLiteCloudError.taskError(.errorWritingBlob)
                    logError(category: "BLOB", message: "🚨 Blob writing failed: \(error)")
                    throw error
                }
            }
            
            // Checks if writing is failed.
            if SQCloudIsError(conn) {
                let error = SQLiteCloudError.handleError(connection: conn)
                logError(category: "BLOB", message: "🚨 Blob writing failed: \(error)")
                throw error
            }
            
            // logging
            logDebug(category: "BLOB", message: "🗃️ Blob writing successful - rowId \(row.rowId) - bytes: \(dataBytesCount)")
        }
    }
}

// MARK: - VM API

public extension SQLiteCloud {
    /// Compiles an SQL query into a byte-code virtual machine (VM). This method creates a 
    /// `SQLiteCloudVM` instance that you can use to execute the compiled SQL statement.
    ///
    /// - Parameters:
    ///   - query: The SQL query to compile.
    ///
    /// - Throws:
    ///   - `SQLiteCloudError.connectionFailure`: If the connection to the SQLite Cloud 
    ///     backend has failed. More details can be found in the associated value
    ///     `SQLiteCloudError.ConnectionContext`.
    ///
    ///   - `SQLiteCloudError.handleError`: If an error occurs while handling the SQLite 
    ///     Cloud operation.
    ///
    /// - Returns:
    ///   A `SQLiteCloudVM` instance representing the compiled virtual machine for the SQL
    ///    query. You can use this VM to execute the SQL statement.
    ///
    ///  Example usage:
    ///  
    ///  ```swift
    ///  let query = "SELECT * FROM your_table"
    ///  let vm = try await sqliteCloud.compile(query: query)
    ///  try await vm.step()
    ///  ```
    func compile(query: String) async throws -> SQLiteCloudVM {
        // Checks if connection is open and valid.
        let conn = try getConnection()

        // Compile an SQL statement into a byte-code virtual machine. 
        // This function resembles the sqlite3_prepare SQLite API.
        let vm = SQCloudVMCompile(conn, query, -1, nil)
        
        // Checks if compile is failed.
        guard let vm = vm else {
            let error =  SQLiteCloudError.handleError(connection: conn)
            logError(category: "VIRTUAL MACHINE", message: "🚨 VM compile failed: \(error)")
            throw error
        }

        logInfo(category: "VIRTUAL MACHINE", message: "🚀 '\(query)' virtual machine created succesfully")
        return SQLiteCloudVM(vm: vm)
    }
}
