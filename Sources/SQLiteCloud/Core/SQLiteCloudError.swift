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

/// Represents errors that can occur during interactions with the `SQLiteCloud` class.
///
/// `SQLiteCloudError` is an enumeration that encompasses various error scenarios that
/// can arise when working with SQLite Cloud. It provides detailed error context through
/// associated values.
public enum SQLiteCloudError: Error, Sendable {
    case unhandledError
    
    /// An indication that the connection to the cloud has failed.
    /// The reasons can be of various types.
    /// More details can be found in the associated value `SQLiteCloudError.Context`.
    case connectionFailure(SQLiteCloudError.ConnectionContext)
    
    /// An indication that execution of the sql command failed.
    /// More details can be found in the associated value `SQLiteCloudError.Context`.
    case executionFailed(SQLiteCloudError.ExecutionContext)
    
    /// An indication that a generic sqlite error has occurred.
    /// More details can be found in the associated value `SQLiteCloudError.SqlContext`.
    case sqliteError(SQLiteCloudError.SqlContext)

    /// An indication that a upload or download task error has occurred.
    /// More detailt can be found in the associated value `SQLiteCloudError.TaskError`
    case taskError(SQLiteCloudError.TaskError)

    /// An indication that the virtual machine has failed.
    /// The reasons can be of various types.
    /// More details can be found in the associated value `SQLiteCloudError.VMContext`.
    case virtualMachineFailure(SQLiteCloudError.VMContext)
}

public extension SQLiteCloudError {
    /// The context in which the connection error occurred.
    struct ConnectionContext: Sendable {
        /// The error code.
        public let code: Int
        
        /// The errore message.
        public let message: String
    }
    
    /// The context in which the exec error occurred.
    struct ExecutionContext: Sendable {
        /// The error code.
        public let code: Int
        
        /// The errore message.
        public let message: String
    }
    
    /// The context in which the sql error occurred.
    struct SqlContext: Sendable {
        /// The error code.
        public let code: Int
        
        /// The errore message.
        public let message: String
    
        /// The extended error code.
        public let extendedErrorCode: Int
        
        /// The offset
        public let offset: Int
    }

    /// The context in which the task error occurred.
    struct TaskError: Sendable {
        /// The error code.
        public let code: Int

        /// The errore message.
        public let message: String
    }

    /// The context in which the virtual machine error occurred.
    struct VMContext: Sendable {
        /// The error code.
        public let code: Int

        /// The errore message.
        public let message: String
    }
}
