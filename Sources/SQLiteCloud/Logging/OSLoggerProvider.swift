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

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
final class OSLoggerProvider: LoggerProvider {
    let subsystem: String
    
    private var loggers: [String: os.Logger] = [:]
    
    init(subsystem: String) {
        self.subsystem = subsystem
    }
    
    func log(level: SQLogger.Level, category: String, message: String) {
        let logger = getLogger(for: category)
        logger.log(level: level.osLogType, "\(message, privacy: .public)")
    }
    
    func getLogger(for category: String) -> os.Logger {
        if let logger = loggers[category] {
            return logger
        }
        
        let logger = os.Logger(subsystem: subsystem, category: category)
        loggers[category] = logger
        return logger
    }
}
