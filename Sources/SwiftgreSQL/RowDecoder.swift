//
//  RowDecoder.swift
//
//
//  Created by Soroush Khanlou on 11/1/20.
//

import Foundation

extension Row {
    public func decode<T: Decodable>(_ type: T.Type = T.self) throws -> T {
        try RowDecoder().decode(type, from: self)
    }
}

extension Array where Element == Row {
    public func decode<T: Decodable>(_ type: T.Type = T.self) throws -> [T] {
        try self.map({ row in
            return try row.decode(type)
        })
    }
}

public class RowDecoder {

    class _RowDecoder: Decoder {

        let row: Row

        var codingPath: [CodingKey] = []

        var userInfo: [CodingUserInfoKey: Any] = [:]

        init(row: Row, codingPath: [CodingKey]) {
            self.row = row
            self.codingPath = codingPath
        }

        private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {

            var row: Row {
                decoder.row
            }

            let decoder: _RowDecoder

            var codingPath: [CodingKey] = []

            var allKeys: [Key] {
                row.fields.keys.compactMap({ Key(stringValue: $0) })
            }

            func value(for key: Key) throws -> PostgresDataType {
                guard let value = row[key.stringValue] else {
                    throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key \"\(key.stringValue)\" not found."))
                }
                return value
            }

            func contains(_ key: Key) -> Bool {
                row.fields.keys.contains(key.stringValue)
            }

            func decodeNil(forKey key: Key) throws -> Bool {
                try value(for: key).isNull
            }

            func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
                guard let bool = try value(for: key).bool else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected a boolean for key \(key)")
                }
                return bool
            }

            func decode(_ type: String.Type, forKey key: Key) throws -> String {
                guard let string = try value(for: key).string else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected a string for key \(key)")
                }
                return string
            }

            func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
                guard let double = try value(for: key).double else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected a double for key \(key)")
                }
                return double
            }

            func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
                guard let double = try value(for: key).double else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected a float for key \(key)")
                }
                return Float(double)
            }

            func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
                guard let int = try value(for: key).int else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected an int for key \(key)")
                }
                return int
            }

            func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
                guard let int = try value(for: key).int else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected an int for key \(key)")
                }
                return Int8(int)
            }

            func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
                guard let int = try value(for: key).int else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected an int for key \(key)")
                }
                return Int16(int)
            }

            func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
                guard let int = try value(for: key).int else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected an int for key \(key)")
                }
                return Int32(int)
            }

            func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
                guard let int = try value(for: key).int else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected an int for key \(key)")
                }
                return Int64(int)
            }

            func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
                guard let int = try value(for: key).int else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected an int for key \(key)")
                }
                return UInt(int)
            }

            func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
                guard let int = try value(for: key).int else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected an int for key \(key)")
                }
                return UInt8(int)
            }

            func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
                guard let int = try value(for: key).int else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected an int for key \(key)")
                }
                return UInt16(int)
            }

            func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
                guard let int = try value(for: key).int else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected an int for key \(key)")
                }
                return UInt32(int)
            }

            func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
                guard let int = try value(for: key).int else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected an int for key \(key)")
                }
                return UInt64(int)
            }

            func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
                if type == Date.self {
                    if let date = try value(for: key).date {
                        return date as! T
                    } else {
                        throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected an date for key \(key)")
                    }
                } else {
                    return try T(from: _RowDecoder(row: row, codingPath: self.codingPath + [key]))
                }
            }

            func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
                throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Nesting not currently supported in RowDecoder")
            }

            func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
                throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Nesting not currently supported in RowDecoder")
            }

            func superDecoder() throws -> Decoder {
                decoder
            }

            func superDecoder(forKey key: Key) throws -> Decoder {
                decoder
            }

        }

        struct SingleValueContainer: SingleValueDecodingContainer {
            var codingPath: [CodingKey]

            var decoder: _RowDecoder

            var row: Row {
                decoder.row
            }

            var lastKey: CodingKey {
                codingPath.last!
            }

            func valueForLastKey() throws -> PostgresDataType {
                guard let value = row[lastKey.stringValue] else {
                    throw DecodingError.keyNotFound(lastKey, DecodingError.Context(codingPath: codingPath, debugDescription: "Key \"\(lastKey.stringValue)\" not found."))
                }
                return value
            }

            func decodeNil() -> Bool {
                (try? valueForLastKey().bool) ?? false
            }

            func decode(_ type: Bool.Type) throws -> Bool {
                guard let bool = try valueForLastKey().bool else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a boolean for the unkeyed container at key \(lastKey)")
                }
                return bool
            }

            func decode(_ type: String.Type) throws -> String {
                if let string = try valueForLastKey().string {
                    return string
                } else if let data = try valueForLastKey().bytes, let string = String(data: data, encoding: .utf8) {
                    return string
                } else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a string for the unkeyed container at key \(lastKey)")
                }
            }

            func decode(_ type: Double.Type) throws -> Double {
                guard let double = try valueForLastKey().double else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a double for the unkeyed container at key \(lastKey)")
                }
                return double
            }

            func decode(_ type: Float.Type) throws -> Float {
                guard let double = try valueForLastKey().double else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a double for the unkeyed container at key \(lastKey)")
                }
                return Float(double)
            }

            func decode(_ type: Int.Type) throws -> Int {
                guard let int = try valueForLastKey().int else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a int for the unkeyed container at key \(lastKey)")
                }
                return int
            }

            func decode(_ type: Int8.Type) throws -> Int8 {
                guard let int = try valueForLastKey().int else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a int for the unkeyed container at key \(lastKey)")
                }
                return Int8(int)
            }

            func decode(_ type: Int16.Type) throws -> Int16 {
                guard let int = try valueForLastKey().int else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a int for the unkeyed container at key \(lastKey)")
                }
                return Int16(int)
            }

            func decode(_ type: Int32.Type) throws -> Int32 {
                guard let int = try valueForLastKey().int else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a int for the unkeyed container at key \(lastKey)")
                }
                return Int32(int)
            }

            func decode(_ type: Int64.Type) throws -> Int64 {
                guard let int = try valueForLastKey().int else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a int for the unkeyed container at key \(lastKey)")
                }
                return Int64(int)
            }

            func decode(_ type: UInt.Type) throws -> UInt {
                guard let int = try valueForLastKey().int else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a int for the unkeyed container at key \(lastKey)")
                }
                return UInt(int)
            }

            func decode(_ type: UInt8.Type) throws -> UInt8 {
                guard let int = try valueForLastKey().int else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a int for the unkeyed container at key \(lastKey)")
                }
                return UInt8(int)
            }

            func decode(_ type: UInt16.Type) throws -> UInt16 {
                guard let int = try valueForLastKey().int else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a int for the unkeyed container at key \(lastKey)")
                }
                return UInt16(int)
            }

            func decode(_ type: UInt32.Type) throws -> UInt32 {
                guard let int = try valueForLastKey().int else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a int for the unkeyed container at key \(lastKey)")
                }
                return UInt32(int)
            }

            func decode(_ type: UInt64.Type) throws -> UInt64 {
                guard let int = try valueForLastKey().int else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a int for the unkeyed container at key \(lastKey)")
                }
                return UInt64(int)
            }

            func decode(_ type: Date.Type) throws -> Date {
                guard let date = try valueForLastKey().date else {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "Expected a date for the unkeyed container at key \(lastKey)")
                }
                return date
            }

            func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
                try T(from: self.decoder)
            }
        }

        func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
            return KeyedDecodingContainer(KeyedContainer<Key>(decoder: self, codingPath: self.codingPath))
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            fatalError("Unkeyed containers are not supported")
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            SingleValueContainer(codingPath: codingPath, decoder: self)
        }
    }

    func decode<T: Decodable>(_ type: T.Type = T.self, from row: Row) throws -> T {
        try T(from: _RowDecoder(row: row, codingPath: []))
    }
}
