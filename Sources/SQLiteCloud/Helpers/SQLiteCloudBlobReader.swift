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

typealias BlobReaderCallback = (UnsafeMutableRawPointer, Int32, Int32) throws -> Void

struct SQLiteCloudBlobReader {
    let blobSizeThreshold: Int
    let blobChunkHandler: CalculateChunkHandler
    
    init(blobSizeThreshold: Int = defaultBlobSizeThreshold, blobChunkHandler: @escaping CalculateChunkHandler) {
        self.blobSizeThreshold = blobSizeThreshold
        self.blobChunkHandler = blobChunkHandler
    }
}

extension SQLiteCloudBlobReader {
    func read(row: SQLiteCloudBlobRead.Row,
              totalSize: Int32,
              progressHandler: ProgressHandler?,
              callback: BlobReaderCallback) throws -> SQLiteCloudBlobReadResult {
        let chunkSize = Int32(totalSize > blobSizeThreshold ? blobChunkHandler(Int(totalSize)) : Int(totalSize))
        
        let rowPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(totalSize))
        defer { rowPointer.deallocate() }

        // create new output stream
        let stream: OutputStream
        switch row.dataDestination {
        case .data:
            stream = OutputStream(toBuffer: rowPointer, capacity: Int(totalSize))
            
        case .url(let url):
            guard let outputStream = OutputStream(url: url, append: true) else {
                throw SQLiteCloudError.taskError(.cannotCreateOutputFile)
            }
            stream = outputStream
        }
        
        stream.open()
        
        var offset: Int32 = 0
        while offset < totalSize {
            let bufferSize = min(chunkSize, (totalSize - offset))
            let rowBuffer = UnsafeMutableRawPointer.allocate(byteCount: Int(bufferSize), alignment: MemoryLayout<UInt8>.alignment)
            defer { rowBuffer.deallocate() }
            
            try callback(rowBuffer, bufferSize, offset)
            let written = stream.write(rowBuffer, maxLength: Int(bufferSize))
            if written < 0 {
                throw SQLiteCloudError.taskError(.cannotCreateOutputFile)
            }
            
            offset += bufferSize
            progressHandler?(Double(offset) / Double(totalSize))
        }
        
        stream.close()
        
        switch row.dataDestination {
        case .data:
            return .data(Data(bytes: rowPointer, count: Int(totalSize)))
            
        case .url(let url):
            return .url(url)
        }
    }
}
