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
import OSLog

final class SQLogger {
    let provider: LoggerProvider
    var isLoggingEnabled = true
    
    static let instance = SQLogger(subsystem: "io.sqlitecloud.SwiftSDK")
    
    init(subsystem: String) {
        if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
            provider = OSLoggerProvider(subsystem: subsystem)
        } else {
            provider = PrintLoggerProvider(subsystem: subsystem)
        }
    }
}

extension SQLogger {
    func log(level: Level, category: String, message: String) {
        guard isLoggingEnabled else { return }
        provider.log(level: level, category: category, message: message)
    }
}

extension SQLogger {
    enum Level {
        case `default`
        case info
        case debug
        case error
        case fault
        
        var osLogType: OSLogType {
            switch self {
            case .default:
                return .default
                
            case .info:
                return .info
                
            case .debug:
                return .debug
                
            case .error:
                return .error
                
            case .fault:
                return .fault
            }
        }
    }
}
