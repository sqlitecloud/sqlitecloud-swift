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

enum ResultParser {
    static func parse(result: OpaquePointer, connection: OpaquePointer) throws -> SQLiteCloudResult {
        let resulType = SQCloudResultType(result)
        
        switch resulType {
        case RESULT_OK:
            return .success
                   
        case RESULT_ERROR:
            throw SQLiteCloudError.handleError(connection: connection)
                   
        case RESULT_NULL:
            return .value(.null)

        case RESULT_STRING:
            if SQCloudResultLen(result) != 0 {
                let text = String(format: "%.*s", SQCloudResultLen(result), SQCloudResultBuffer(result))
                return .value(.string(text))
            }

            return .value(.string(.empty))
                   
        case RESULT_JSON:
            if SQCloudResultLen(result) > 0 {
                let text = String(format: "%.*s", SQCloudResultLen(result), SQCloudResultBuffer(result))
                return .json(text)
            }
            return .json(.empty)
        
        case RESULT_INTEGER:
            let value = SQCloudResultInt64(result)
            return .value(.integer(Int(value)))
               
        case RESULT_FLOAT:
            let value = SQCloudResultDouble(result)
            return .value(.double(value))
            
        case RESULT_ARRAY:
            let array = try parse(array: result)
            return .array(array)
                   
        case RESULT_ROWSET:
            let rowset = try parse(rowset: result)
            return .rowset(rowset)
                   
        case RESULT_BLOB:
            if SQCloudResultLen(result) > 0 {
                if let buffer = SQCloudResultBuffer(result) {
                    let count = SQCloudResultLen(result)
                    let data = Data(bytes: buffer, count: Int(count))
                    return .value(.blob(data))
                }
            }
            
            return .value(.blob(.empty))
            
        default:
            throw SQLiteCloudError.executionFailed(.unsupportedResultType)
        }
    }
    
    static func parse(rowset: OpaquePointer) throws -> SQLiteCloudRowset {
        guard SQCloudResultType(rowset) == RESULT_ROWSET else {
            throw SQLiteCloudError.executionFailed(.unsupportedResultType)
        }
        
        let nrows = SQCloudRowsetRows(rowset)
        let ncols = SQCloudRowsetCols(rowset)

        let columns = (0..<ncols).map { index -> String in
            var len: Int32 = 0
            if let value = SQCloudRowsetColumnName(rowset, index, &len) {
                return String(format: "%.*s", len, value)
            }
            
            return .empty
        }
        
        let rows = try (0..<nrows).map { rowIndex in
            try (0..<ncols).map { columnIndex -> SQLiteCloudValue in
                let valueType = SQCloudRowsetValueType(rowset, rowIndex, columnIndex)
                
                switch valueType {
                case VALUE_INTEGER:
                    let value = SQCloudRowsetInt64Value(rowset, rowIndex, columnIndex)
                    return .integer(Int(value))
                    
                case VALUE_FLOAT:
                    let value = SQCloudRowsetDoubleValue(rowset, rowIndex, columnIndex)
                    return .double(value)

                case VALUE_TEXT:
                    var len: Int32 = 0
                    if let value = SQCloudRowsetValue(rowset, rowIndex, columnIndex, &len) {
                        return .string(String(format: "%.*s", len, value))
                    }
                    return .string(.empty)
                        
                case VALUE_BLOB:
                    var len: Int32 = 0
                    if let value = SQCloudRowsetValue(rowset, rowIndex, columnIndex, &len) {
                        let count = len
                        let data = Data(bytes: value, count: Int(count))
                        return .blob(data)
                    }
                    return .blob(.empty)
                    
                case VALUE_NULL:
                    return .null
                    
                default:
                    throw SQLiteCloudError.executionFailed(.unsupportedValueType)
                }
            }
        }
        
        return SQLiteCloudRowset(columns: columns, rows: rows)
    }
    
    static func parse(array: OpaquePointer) throws -> [SQLiteCloudValue] {
        guard SQCloudResultType(array) == RESULT_ARRAY else {
            throw SQLiteCloudError.executionFailed(.unsupportedResultType)
        }
        
        let count = SQCloudArrayCount(array)
        let result = try (0..<count).map { index -> SQLiteCloudValue  in
            let valueType = SQCloudArrayValueType(array, index)
            
            switch valueType {
            case VALUE_INTEGER:
                let value = SQCloudArrayInt64Value(array, index)
                return .integer(Int(value))
                
            case VALUE_FLOAT:
                let value = SQCloudArrayDoubleValue(array, index)
                return .double(value)

            case VALUE_TEXT:
                var len: Int32 = 0
                if let value = SQCloudArrayValue(array, index, &len) {
                    return .string(String(format: "%.*s", len, value))
                }
                return .string(.empty)
                    
            case VALUE_BLOB:
                var len: Int32 = 0
                if let value = SQCloudArrayValue(array, index, &len) {
                    let count = len
                    let data = Data(bytes: value, count: Int(count))
                    return .blob(data)
                }
                return .blob(.empty)
                
            case VALUE_NULL:
                return .null
                
            default:
                throw SQLiteCloudError.executionFailed(.unsupportedValueType)
            }
        }
        
        return result
    }
}
