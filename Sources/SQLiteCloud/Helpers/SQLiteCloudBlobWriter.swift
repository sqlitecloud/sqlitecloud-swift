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

typealias BlobWriteCallback = (UnsafeRawPointer?, Int32, Int32) throws -> Void

struct SQLiteCloudBlobWriter: Sendable {
    let blobSizeThreshold: Int
    let blobChunkHandler: CalculateChunkHandler
    
    init(blobSizeThreshold: Int = defaultBlobSizeThreshold, blobChunkHandler: @escaping CalculateChunkHandler) {
        self.blobSizeThreshold = blobSizeThreshold
        self.blobChunkHandler = blobChunkHandler
    }
}

// MARK: - Private methods

private extension SQLiteCloudBlobWriter {
    func calculateChunkSize(dataSize: Int) -> Int {
        dataSize > blobSizeThreshold ? blobChunkHandler(dataSize) : dataSize
    }
    
    func write(data: Data, 
               progressHandler: ProgressHandler?,
               callback: @escaping BlobWriteCallback) throws {
        var offset = 0
        let dataSize = data.count
        let chunkSize = calculateChunkSize(dataSize: dataSize)
        
        try data.withUnsafeBytes { (rawPointer: UnsafeRawBufferPointer) in
            while offset < data.count {
                let bufferSize = min(chunkSize, (rawPointer.count - offset))
                let upperBound = (offset + bufferSize)
                let slice = rawPointer[offset..<upperBound]
                let buffer = UnsafeRawBufferPointer(rebasing: slice)
                
                try callback(buffer.baseAddress, Int32(bufferSize), Int32(offset))
                offset += bufferSize
                progressHandler?(Double(offset) / Double(dataSize))
            }
        }
    }
    
    func write(url: URL, progressHandler: ProgressHandler?, callback: @escaping BlobWriteCallback) throws {
        let dataSize = try url.fileSize()
        let chunkSize = calculateChunkSize(dataSize: dataSize)
        
        guard dataSize > chunkSize else {
            let data = try Data(contentsOf: url)
            try write(data: data, progressHandler: progressHandler, callback: callback)
            return
        }
        
        var offset = 0
        let bufferSize = blobChunkHandler(dataSize)
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        guard let inputStream = InputStream(fileAtPath: url.path) else { return }
        inputStream.open()
        defer { inputStream.close() }

        while inputStream.hasBytesAvailable {
            let bufferLen = Int32(offset)
            let read = inputStream.read(buffer, maxLength: bufferSize)
            try callback(buffer, Int32(read), bufferLen)
            offset += read
            progressHandler?(Double(offset) / Double(dataSize))
        }
    }
}

// MARK: - Internal

extension SQLiteCloudBlobWriter {
    func writeBlob(row: SQLiteCloudBlobWrite.Row,
                   progressHandler: ProgressHandler?,
                   callback: @escaping BlobWriteCallback) throws {
        switch row.dataSource {
        case .data(let data):
            try write(data: data, progressHandler: progressHandler, callback: callback)
            
        case .url(let url):
            try write(url: url, progressHandler: progressHandler, callback: callback)
        }
    }
}
