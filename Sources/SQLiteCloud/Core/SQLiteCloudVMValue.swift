//
//  SQLiteCloud
//
//  Created by Dimitri Giani.
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

/// Represents values that can be stored in SQLite Virtual Machine Cloud.
///
/// The `SQLiteCloudVMValue` enumeration is used to represent various types of values
/// that can be stored in SQLite Cloud. These values include integers, doubles,
/// strings, blobs (binary data), and null values.
public enum SQLiteCloudVMValue: Hashable, Sendable {
    case integer(Int)
    case integer64(Int64)
    case double(Double)
    case string(String)
    case blob(Data)
    case blobZero
    case null
}

// MARK: - Internal

extension SQLiteCloudVMValue {
    var strlen: Int {
        switch self {
        case .integer:
            return 0

        case .integer64:
            return 0

        case .double:
            return 0

        case .string(let string):
            // swiftlint:disable force_unwrapping
            return Darwin.strlen(string.cString(using: .utf8)!)
            // swiftlint:enable force_unwrapping

        case .blob(let data):
            return data.count

        case .blobZero:
            return 0

        case .null:
            return 0
        }
    }
}
