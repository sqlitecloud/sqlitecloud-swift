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

/// Represents a message that can be sent via SQLite Cloud.
///
/// A `SQLiteCloudMessage` encapsulates a message to be sent over SQLite Cloud. It includes
/// the message content, the target channel, and an option to create the channel if it does
/// not exist.
///
/// - Parameters:
///   - channel: A string specifying the target channel for the message.
///   - payload: The payload of the message, which conforms to the `Payloadable` protocol.
///   - createChannelIfNotExist: A boolean value indicating whether to create the target 
///                              channel if it does not exist. The default is `false`.
///
/// - Note: The `Payload` type must conform to the `Payloadable` protocol. Channels are used
///         to categorize messages, allowing clients to subscribe to specific channels of interest.
public struct SQLiteCloudMessage<Payload: Payloadable>: Sendable {
    public let channel: String
    public let payload: Payload
    public let createChannelIfNotExist: Bool
    
    public init(channel: String, payload: Payload, createChannelIfNotExist: Bool = false) {
        self.channel = channel
        self.payload = payload
        self.createChannelIfNotExist = createChannelIfNotExist
    }
}
