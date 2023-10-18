//
//  File.swift
//  
//
//  Created by Massimo Oliviero on 18/10/23.
//

import Foundation

/// The `SQLiteCloudProvider` protocol defines a set of methods to interact 
/// with a SQLiteCloud instance. Implement this protocol to establish
/// connections, execute SQL commands, and perform various operations with
/// SQLite databases in a cloud environment.
public protocol SQLiteCloudProvider {
    /// Initializes a new instance of the `SQLiteCloudProvider` actor with the provided
    /// configuration.
    ///
    /// This initializer creates a new `SQLiteCloudProvider` instance using the specified
    /// configuration settings. The configuration includes details such as the
    /// hostname, port, username, password, and various connection options. Once
    /// initialized, you can use this instance to interact with SQLite Cloud by
    /// calling its methods.
    ///
    ///  - Parameter config: The SQLiteCloudConfig object containing connection
    ///                      and configuration details such as hostname, port,
    ///                      username, password, and other options.
    init(config: SQLiteCloudConfig)
    
    // MARK: - Configurations
        
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
    func set(isLoggingEnabled: Bool) async
    
    // MARK: - Connection API
    
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
    func connect() async throws
    
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
    func disconnect() async throws
    
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
    func getClientUUID() async throws -> UUID
    
    // MARK: - Execute API
    
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
    func execute(command: SQLiteCloudCommand) async throws -> SQLiteCloudResult
    
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
    func execute(query: String) async throws -> SQLiteCloudResult
    
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
    func execute(query: String, _ parameters: SQLiteCloudValue...) async throws -> SQLiteCloudResult
    
    // MARK: - Pub/Sub API
    
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
    func create(channel: String, ifNotExists: Bool) async throws -> SQLiteCloudResult
    
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
    func notify<P: Payloadable>(message: SQLiteCloudMessage<P>) async throws -> SQLiteCloudResult
    
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
    func listen(to channel: SQLiteCloudChannel, callback: @escaping NotificationHandler) async throws -> Disposable
    
    // MARK: - Upload/Download database API
    
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
    func upload(database: SQLiteCloudUploadDatabase, progressHandler: @escaping ProgressHandler) async throws
    
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
    func download(database: SQLiteCloudDownloadDatabase, progressHandler: @escaping ProgressHandler) async throws -> URL
    
    // MARK: - Blob API
    
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
    func sizeInBytes(blob: SQLiteCloudBlobRead) async throws -> [Int32]
    
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
    func read(blob: SQLiteCloudBlobRead, progressHandler: ProgressHandler?) async throws -> [SQLiteCloudBlobReadResult]
    
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
    func update(blob: SQLiteCloudBlobWrite, progressHandler: ProgressHandler?) async throws
    
    // MARK: - VM
    
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
    func compile(query: String) async throws -> SQLiteCloudVM
}

public extension SQLiteCloudProvider {
    func read(blob: SQLiteCloudBlobRead) async throws -> [SQLiteCloudBlobReadResult] {
        try await read(blob: blob, progressHandler: nil)
    }
    
    func update(blob: SQLiteCloudBlobWrite) async throws {
        try await update(blob: blob, progressHandler: nil)
    }
}
