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

class UploadHelper {
    private let inputStream: InputStream

    let progressHandler: (Double) -> Void
    let fileSize: Int

    deinit {
        inputStream.close()
    }

    init(url: URL, progressHandler: @escaping ProgressHandler) throws {
        if let inputStream = InputStream(fileAtPath: url.path) {
            self.fileSize = (try Data(contentsOf: url)).count
            self.inputStream = inputStream
            self.progressHandler = progressHandler
            self.inputStream.open()
        } else {
            throw SQLiteCloudError.taskError(.urlHandlerFailed)
        }
    }

    func read(buffer: UnsafeMutableRawPointer, length: Int) -> Int {
        inputStream.read(buffer, maxLength: length)
    }
}

extension UploadHelper {
    static func result(dataHandler: UploadHelper,
                       buffer: UnsafeMutableRawPointer?,
                       bufferLength: UnsafeMutablePointer<UInt32>?,
                       totalLength: Int64,
                       previousProgress: Int64) -> (result: Int32, completed: Bool) {
        if let buffer,
           let length = bufferLength?.pointee {
            let result = dataHandler.read(buffer: buffer, length: Int(length))

            // If the data read is negative, there is a problem.
            if result == -1 {
                return (-1, true)
            }

            // Check the progress of the stream.
            if result != 0 {
                let progress = (Double(previousProgress) + Double(result)) / Double(totalLength)
                dataHandler.progressHandler(progress)
            }

            bufferLength?.pointee = UInt32(result)

            return (0, result == 0)
        } else {
            return (-1, true)
        }
    }
}
