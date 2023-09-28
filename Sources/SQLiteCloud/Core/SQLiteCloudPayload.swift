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

public struct SQLiteCloudPayload {
    public let sender: UUID
    public let channel: String
    public let messageType: MessageType
    public let pk: [String]
    public let payload: String?
}

// MARK: - Codable

extension SQLiteCloudPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case sender
        case channel
        case messageType = "type"
        case pk
        case payload
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.sender = try container.decode(UUID.self, forKey: .sender)
        self.channel = try container.decode(String.self, forKey: .channel)
        self.messageType = try container.decode(MessageType.self, forKey: .messageType)
        self.pk = try container.decodeIfPresent([String].self, forKey: .pk) ?? []
        self.payload = try container.decodeIfPresent(String.self, forKey: .payload) ?? .empty
    }
}

// MARK: - CustomDebugStringConvertible

extension SQLiteCloudPayload: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        - sender: \(sender)
        - channel: \(channel)
        - message type: \(messageType.rawValue)
        - pk: \(pk)
        - payload: \(payload ?? "(empty)")
        """
    }
}

// MARK: - Nested types

public extension SQLiteCloudPayload {
    enum MessageType: String, Codable {
        case table = "TABLE"
        case message = "MESSAGE"
        case insert = "INSERT"
        case update = "UPDATE"
        case delete = "DELETE"
        case notSupported
    }
}
