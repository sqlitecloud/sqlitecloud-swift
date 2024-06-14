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

/// An enumeration representing the value types used in SQLiteCloud for database values.
public enum SQLiteCloudValueType: Int, Sendable {
    /// An integer value.
    case integer = 1
    
    /// A floating-point (double) value.
    case float = 2
    
    /// A text (string) value.
    case text = 3
    
    /// A binary large object (blob) value.
    case blob = 4
    
    /// A null value.
    case null = 5
    
    /// An unknown or unsupported value type.
    case unknown = -1
}

