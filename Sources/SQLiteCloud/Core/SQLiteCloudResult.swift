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

/// An enumeration representing the result of a query or operation in SQLiteCloud.
public enum SQLiteCloudResult: Hashable, Sendable {
    /// The operation was successful with no specific data.
    case success

    /// A result in JSON format as a string.
    case json(String)

    /// A single value result.
    case value(SQLiteCloudValue)

    /// An array of values as a result.
    case array([SQLiteCloudValue])

    /// A rowset containing columns and rows.
    case rowset(SQLiteCloudRowset)
}

public extension SQLiteCloudResult {
    var stringValue: String? {
        switch self {
        case .value(let value):
            return value.stringValue
            
        case .json(let string):
            return string
            
        case .array(let array):
            return "\(array)"
            
        case .rowset(let rowset):
            return "\(rowset)"
            
        case .success:
            return "success"
        }
    }
}
