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

public struct SQLiteCloudBlobRead: Sendable {
    public let info: SQLiteCloudBlobInfo
    public let rows: [Row]
    public let blobSizeThreshold: Int
    public let blobChunkHandler: CalculateChunkHandler
    
    public init(info: SQLiteCloudBlobInfo,
                rows: [Row],
                blobSizeThreshold: Int = defaultBlobSizeThreshold,
                blobChunkHandler: @escaping CalculateChunkHandler = defaultChunkHandler) {
        self.info = info
        self.rows = rows
        self.blobSizeThreshold = blobSizeThreshold
        self.blobChunkHandler = blobChunkHandler
    }
    
    public init(info: SQLiteCloudBlobInfo,
                row: Row,
                blobSizeThreshold: Int = defaultBlobSizeThreshold,
                blobChunkHandler: @escaping CalculateChunkHandler = defaultChunkHandler) {
        self.init(info: info,
                  rows: [row],
                  blobSizeThreshold: blobSizeThreshold,
                  blobChunkHandler: blobChunkHandler)
    }
    
    public init(scheme: String? = nil,
                table: String,
                column: String,
                row: Row,
                blobSizeThreshold: Int = defaultBlobSizeThreshold,
                blobChunkHandler: @escaping CalculateChunkHandler = defaultChunkHandler) {
        self.init(info: SQLiteCloudBlobInfo(schema: scheme, table: table, column: column),
                  row: row,
                  blobSizeThreshold: blobSizeThreshold,
                  blobChunkHandler: blobChunkHandler)
    }
}

public extension SQLiteCloudBlobRead {
    struct Row: Sendable {
        public let rowId: Int
        public let dataDestination: DataDestination
        
        public init(rowId: Int, dataDestination: DataDestination) {
            self.rowId = rowId
            self.dataDestination = dataDestination
        }
    }
    
    enum DataDestination: Sendable {
        case data
        case url(URL)
    }
}
