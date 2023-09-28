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

// swiftlint:disable force_unwrapping

/// Scans a sequence and accumulates values using a combining function.
///
/// This function iterates over a sequence, applying a combining function to each element and
/// accumulating the results in an array. It is useful for generating running totals or
/// intermediate values based on the elements of a sequence.
///
/// - Parameters:
///   - seq: The input sequence to be scanned.
///   - initial: The initial value of the accumulator.
///   - combine: A function that combines the current accumulator value and the next element of the sequence.
///
/// - Returns: An array of accumulated values.
///
/// - Note: This function is often used to generate arrays of accumulated values based on a
///         sequence. It can be helpful in various algorithms and data processing tasks.
///
/// - SeeAlso: [Swift Standard Library](https://developer.apple.com/documentation/swift/array/1779942-scan)
private func scan<S: Sequence, U>(_ seq: S, _ initial: U, _ combine: (U, S.Iterator.Element) -> U) -> [U] {
    var result: [U] = []
    result.reserveCapacity(seq.underestimatedCount)
    var runningResult = initial
    for element in seq {
        runningResult = combine(runningResult, element)
        result.append(runningResult)
    }
    return result
}

/// Converts an array of Swift strings to an array of C-style null-terminated strings and passes
/// it to a callback function for use in C interfaces.
///
/// This function is used when interfacing with C code that expects an array of C-style strings 
/// (char*) or an array of pointers to such strings (char**). Swift automatically performs the
/// necessary conversions.
///
/// - Parameters:
///   - args: An array of Swift strings to be converted to C-style strings.
///   - body: A callback function that takes an array of UnsafePointer to C-style strings.
///
/// - Returns: The result of the callback function.
///
/// - Note: This function is helpful when dealing with C APIs that require arrays of C-style
///         strings. It takes an array of Swift strings, converts them to C-style strings, and
///         invokes the provided callback function with the resulting array. The callback function
///         can then interact with the C interface using the converted strings.
///
/// - SeeAlso: [Swift Private Repository](https://github.com/apple/swift/blob/c3b7709a7c4789f1ad7249d357f69509fb8be731/stdlib/private/SwiftPrivate/SwiftPrivate.swift#L68-L90)
func withArrayOfCStrings<R>(_ args: [String], _ body: ([UnsafePointer<CChar>?]) -> R) -> R {
    let argsCounts = Array(args.map { $0.utf8.count + 1 })
    let argsOffsets = [ 0 ] + scan(argsCounts, 0, +)
    let argsBufferSize = argsOffsets.last ?? 0
    
    var argsBuffer: [UInt8] = []
    argsBuffer.reserveCapacity(argsBufferSize)
    for arg in args {
        argsBuffer.append(contentsOf: arg.utf8)
        argsBuffer.append(0)
    }
    
    return argsBuffer.withUnsafeMutableBufferPointer { argsBuffer in
        let ptr = UnsafeMutableRawPointer(argsBuffer.baseAddress!).bindMemory(to: CChar.self, capacity: argsBuffer.count)
        var cStrings: [UnsafePointer<CChar>?] = argsOffsets.map { ptr + $0 }.map { UnsafePointer($0) }
        cStrings[cStrings.count - 1] = nil
        return body(cStrings)
    }
}
// swiftlint:enable force_unwrapping
