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

public struct SQLiteCloudBlobWrite: Sendable {
    public let info: SQLiteCloudBlobInfo
    public let rows: [Row]
    public let automaticallyIncreasesBlobSize: Bool
    public let blobSizeThreshold: Int
    public let blobChunkHandler: CalculateChunkHandler
    
    public init(info: SQLiteCloudBlobInfo,
                rows: [Row],
                automaticallyIncreasesBlobSize: Bool = true,
                blobSizeThreshold: Int = defaultBlobSizeThreshold,
                blobChunkHandler: @escaping CalculateChunkHandler = defaultChunkHandler) {
        self.info = info
        self.rows = rows
        self.automaticallyIncreasesBlobSize = automaticallyIncreasesBlobSize
        self.blobSizeThreshold = blobSizeThreshold
        self.blobChunkHandler = blobChunkHandler
    }
    
    public init(info: SQLiteCloudBlobInfo,
                row: Row,
                automaticallyIncreasesBlobSize: Bool = true,
                blobSizeThreshold: Int = defaultBlobSizeThreshold,
                blobChunkHandler: @escaping CalculateChunkHandler = defaultChunkHandler) {
        self.init(info: info,
                  rows: [row],
                  automaticallyIncreasesBlobSize: automaticallyIncreasesBlobSize,
                  blobSizeThreshold: blobSizeThreshold,
                  blobChunkHandler: blobChunkHandler)
    }
    
    public init(schema: String? = nil,
                table: String,
                column: String,
                rows: [Row],
                automaticallyIncreasesBlobSize: Bool = true,
                blobSizeThreshold: Int = defaultBlobSizeThreshold,
                blobChunkHandler: @escaping CalculateChunkHandler = defaultChunkHandler) {
        self.init(info: SQLiteCloudBlobInfo(schema: schema, table: table, column: column),
                  rows: rows,
                  automaticallyIncreasesBlobSize: automaticallyIncreasesBlobSize,
                  blobSizeThreshold: blobSizeThreshold,
                  blobChunkHandler: blobChunkHandler)
    }
    
    public init(schema: String? = nil,
                table: String,
                column: String,
                row: Row,
                automaticallyIncreasesBlobSize: Bool = true,
                blobSizeThreshold: Int = defaultBlobSizeThreshold,
                blobChunkHandler: @escaping CalculateChunkHandler = defaultChunkHandler) {
        self.init(info: SQLiteCloudBlobInfo(schema: schema, table: table, column: column),
                  row: row,
                  automaticallyIncreasesBlobSize: automaticallyIncreasesBlobSize,
                  blobSizeThreshold: blobSizeThreshold,
                  blobChunkHandler: blobChunkHandler)
    }
    
    public init(schema: String? = nil,
                table: String,
                column: String,
                rowId: Int,
                data: Data,
                automaticallyIncreasesBlobSize: Bool = true,
                blobSizeThreshold: Int = defaultBlobSizeThreshold,
                blobChunkHandler: @escaping CalculateChunkHandler = defaultChunkHandler) {
        self.init(info: SQLiteCloudBlobInfo(schema: schema, table: table, column: column),
                  row: Row(rowId: rowId, dataSource: .data(data)),
                  automaticallyIncreasesBlobSize: automaticallyIncreasesBlobSize,
                  blobSizeThreshold: blobSizeThreshold,
                  blobChunkHandler: blobChunkHandler)
    }
}

public extension SQLiteCloudBlobWrite {
    struct Row: Sendable {
        public let rowId: Int
        public let dataSource: DataSource
        
        public init(rowId: Int, dataSource: DataSource) {
            self.rowId = rowId
            self.dataSource = dataSource
        }
    }
    
    enum DataSource: Sendable {
        case data(Data)
        case url(URL)
        
        func bytesCount() throws -> Int {
            switch self {
            case .data(let data):
                return data.count
                
            case .url(let url):
                return try url.fileSize()
            }
        }
    }
}
