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

enum UrlParser {
    static func parse<T: FixedWidthInteger>(items: [URLQueryItem]?, name: String) -> T {
        let queryItems = items ?? []
        let item = queryItems.first { $0.name == name }
        guard let item else { return .zero }
        guard let value = item.value else { return .zero }
        
        return T(value) ?? .zero
    }
    
    static func parse(items: [URLQueryItem]?, name: String) -> Bool {
        let queryItems = items ?? []
        let item = queryItems.first { $0.name == name }
        guard let item else { return false }
        guard let value = item.value else { return false }
        
        return Bool(value) ?? false
    }
    
    static func parse(items: [URLQueryItem]?, name: String) -> String? {
        let queryItems = items ?? []
        let item = queryItems.first { $0.name == name }
        guard let item else { return nil }
        
        return item.value
    }
}
