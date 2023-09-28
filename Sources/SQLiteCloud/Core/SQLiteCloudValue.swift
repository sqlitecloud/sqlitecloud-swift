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

/// Represents values that can be stored in SQLite Cloud.
///
/// The `SQLiteCloudValue` enumeration is used to represent various types of values 
/// that can be stored in SQLite Cloud. These values include integers, doubles,
/// strings, blobs (binary data), and null values.
public enum SQLiteCloudValue: Hashable, Sendable {
    case integer(Int)
    case double(Double)
    case string(String)
    case blob(Data)
    case null
}

public extension SQLiteCloudValue {
    var stringValue: String? {
        switch self {
        case .null:
            return nil
            
        case .integer(let int):
            return "\(int)"
            
        case .double(let double):
            return "\(double)"
            
        case .string(let string):
            return string
            
        case .blob(let data):
            return String(decoding: data, as: UTF8.self)
        }
    }
}

// MARK: - CustomStringConvertible

extension SQLiteCloudValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .null:
            return "nil"
            
        case .integer(let int):
            return "\(int)"
            
        case .double(let double):
            return "\(double)"
            
        case .string(let string):
            return string
            
        case .blob(let data):
            return String(data: data, encoding: .utf8) ?? .empty
        }
    }
}

// MARK: - Internal

extension SQLiteCloudValue {
    var sqlType: SQCLOUD_VALUE_TYPE {
        switch self {
        case .integer:
            return VALUE_INTEGER
            
        case .double:
            return VALUE_FLOAT
            
        case .string:
            return VALUE_TEXT
            
        case .blob:
            return VALUE_BLOB
            
        case .null:
            return VALUE_TEXT
        }
    }
    
    var strlen: Int {
        switch self {
        case .integer:
            return 0
            
        case .double:
            return 0
            
        case .string(let string):
            // swiftlint:disable force_unwrapping
            return Darwin.strlen(string.cString(using: .utf8)!)
            // swiftlint:enable force_unwrapping
            
        case .blob(let data):
            return data.count
            
        case .null:
            return 0
        }
    }
}
