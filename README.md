# SQLiteCloud Swift Package

![sqlitecloud-logo](https://github.com/sqlitecloud/sqlitecloud-swift/assets/3525511/700f1817-dd77-46bc-a0a8-21fe505a9029)


SQLiteCloud is a powerful Swift package that allows you to interact with the SQLite Cloud backend server seamlessly. It provides methods for various database operations and real-time notifications. This package is designed to simplify database operations in Swift applications, making it easier than ever to work with SQLite Cloud.

## Features

- **Database Operations**: Easily perform database operations, including queries, updates, inserts, and more.

- **Real-time Notifications**: Get real-time notifications from the SQLite Cloud backend server.

- **Efficient**: SQLiteCloud is designed for efficiency, ensuring that your database operations are fast and reliable.

- **Swift Native:** Written in Swift for a seamless integration experience.


## Installation

You can install SQLiteCloud Swift Package using Swift Package Manager (SPM). Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/sqlitecloud/swift", from: "0.2.1")
]
```

## Usage

#### Using explicit configuration

```
let configuration = SQLiteCloudConfig(host: "myproject.sqlite.cloud", username: "", password: "", port: .default)
let sqliteCloud = SQLiteCloud(configuration)

do {
	try await sqliteCloud.connect()
	debugPrint("connected")
} catch {
	debugPrint("connection error: \(error)") // SQLiteCloudConnectionError
}
```

#### Using string configuration

```
let configuration = SQLiteCloudConfig(connectionString: "sqlitecloud://user:pass@host.com:port/dbname?timeout=10&key2=value2&key3=value3")
let sqliteCloud = SQLiteCloud(configuration)

do {
	try await sqliteCloud.connect()
	debugPrint("connected")
} catch {
	debugPrint("connection error: \(error)") // SQLiteCloudConnectionError
}
```

## License
SQLiteCloud is licensed under the MIT License. See the LICENSE file for details.
