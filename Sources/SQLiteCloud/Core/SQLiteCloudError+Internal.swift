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

extension SQLiteCloudError.ConnectionContext {
    static let invalidConnection = SQLiteCloudError.ConnectionContext(code: -1, message: "Invalid connection")
    static let invalidUUID = SQLiteCloudError.ConnectionContext(code: -2, message: "Invalid UUID")
}

extension SQLiteCloudError.ExecutionContext {
    static let unsupportedResultType = SQLiteCloudError.ExecutionContext(code: -3, message: "Unsupported result type")
    static let unsupportedValueType = SQLiteCloudError.ExecutionContext(code: -4, message: "Unsupported value type")
}

extension SQLiteCloudError.TaskError {
    static let urlHandlerFailed = SQLiteCloudError.TaskError(code: -5, message: "Cannot create URL Handler")
    static let cannotCreateOutputFile = SQLiteCloudError.TaskError(code: -6, message: "Cannot create output file")
    static let invalidNumberOfRows = SQLiteCloudError.TaskError(code: -7, message: "Invalid number of rows.")
    static let invalidBlobSizeRead = SQLiteCloudError.TaskError(code: -8, message: "Invalid blob size read.")
    static let errorWritingBlob = SQLiteCloudError.TaskError(code: -9, message: "Error writing blob.")
}

extension SQLiteCloudError.VMContext {
    static func invalidParameterIndex(index: Int) -> SQLiteCloudError.VMContext {
        SQLiteCloudError.VMContext(code: -10, message: "Invalid parameter index [\(index)].")
    }
}

extension SQLiteCloudError {
    static func handleError(connection: OpaquePointer?) -> SQLiteCloudError {
        if SQCloudIsError(connection) {
            let code = Int(SQCloudErrorCode(connection))
            let message = String(SQCloudErrorMsg(connection))
            
            if SQCloudIsSQLiteError(connection) {
                let exterr = Int(SQCloudExtendedErrorCode(connection))
                let offerr = Int(SQCloudErrorOffset(connection))
                let context = SQLiteCloudError.SqlContext(code: code, message: message, extendedErrorCode: exterr, offset: offerr)
                return SQLiteCloudError.sqliteError(context)
            } else {
                let context = SQLiteCloudError.ConnectionContext(code: code, message: message)
                return SQLiteCloudError.connectionFailure(context)
            }
        }
        
        return SQLiteCloudError.unhandledError
    }

    static func handleVMError(vm: OpaquePointer?) -> SQLiteCloudError {
        let code = Int(SQCloudVMErrorCode(vm))
        let message = String(SQCloudVMErrorMsg(vm))

        let context = SQLiteCloudError.VMContext(code: code, message: message)
        return SQLiteCloudError.virtualMachineFailure(context)
    }
}
