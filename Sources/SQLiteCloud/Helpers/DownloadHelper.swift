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

class DownloadHelper {
    let outputStream: OutputStream
    let progressHandler: ProgressHandler

    deinit {
        debugPrint("deinit")
        outputStream.close()
    }

    init?(filePath: String, progressHandler: @escaping ProgressHandler) {
        if let stream = OutputStream(toFileAtPath: filePath, append: true) {
            self.outputStream = stream
            self.progressHandler = progressHandler
            self.outputStream.open()
        } else {
            return nil
        }
    }

    func write(buffer: UnsafeRawPointer, length: Int) -> Int {
        outputStream.write(buffer, maxLength: length)
    }
}

extension DownloadHelper {
    static func result(dataHandler: DownloadHelper,
                       buffer: UnsafeRawPointer,
                       bufferLength: UInt32,
                       totalLength: Int64,
                       previousProgress: Int64) -> (result: Int32, completed: Bool) {
        let result = dataHandler.write(buffer: buffer, length: Int(bufferLength))

        if result != bufferLength {
            return (-1, true)
        }

        let progress = Double(previousProgress) / Double(totalLength)
        dataHandler.progressHandler(progress)

        return (0, progress == 1)
    }
}
