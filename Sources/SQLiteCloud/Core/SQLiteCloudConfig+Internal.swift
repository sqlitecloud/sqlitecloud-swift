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

// MARK: - Internal

extension SQLiteCloudConfig {
    var sqConfig: SQCloudConfig {
        var sqConfig = SQCloudConfig()
        sqConfig.family = family.rawValue
        sqConfig.username = (username as NSString).utf8String
        sqConfig.password = (password as NSString).utf8String
        sqConfig.password_hashed = passwordHashed
        sqConfig.nonlinearizable = nonlinearizable
        sqConfig.timeout = Int32(timeout)
        sqConfig.compression = compression
        sqConfig.sqlite_mode = sqliteMode
        sqConfig.zero_text = zerotext
        sqConfig.db_memory = memory
        sqConfig.db_create = dbCreate
        sqConfig.insecure = insecure
        sqConfig.no_blob = noblob
        sqConfig.max_data = Int32(maxData)
        sqConfig.max_rows = Int32(maxRows)
        sqConfig.max_rowset = Int32(maxRowset)
        sqConfig.database = (dbname as? NSString)?.utf8String
        sqConfig.tls_root_certificate = (rootCertificate as? NSString)?.utf8String
        sqConfig.tls_certificate = (clientCertificate as? NSString)?.utf8String
        sqConfig.tls_certificate_key = (clientCertificateKey as? NSString)?.utf8String
        return sqConfig
    }
}
