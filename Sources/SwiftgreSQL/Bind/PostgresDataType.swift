//
//  PostgresDataType.swift
//  
//
//  Created by Soroush Khanlou on 10/30/20.
//

import Foundation

public enum PostgresDataType: Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case null
    case bytes(Data)
    case bool(Bool)
    case array([PostgresDataType])
    case date(Date)
}

public protocol PostgresDataTypeConvertible {
    func convertToPostgresType() -> PostgresDataType
}

extension String: PostgresDataTypeConvertible {
    public func convertToPostgresType() -> PostgresDataType {
        .string(self)
    }
}

extension Int: PostgresDataTypeConvertible {
    public func convertToPostgresType() -> PostgresDataType {
        .int(self)
    }
}

extension Double: PostgresDataTypeConvertible {
    public func convertToPostgresType() -> PostgresDataType {
        .double(self)
    }
}

extension Array: PostgresDataTypeConvertible where Element: PostgresDataTypeConvertible {
    public func convertToPostgresType() -> PostgresDataType {
        .array(self.map({ $0.convertToPostgresType() }))
    }
}

extension Date: PostgresDataTypeConvertible {
    public func convertToPostgresType() -> PostgresDataType {
        .date(self)
    }
}

extension Data: PostgresDataTypeConvertible {
    public func convertToPostgresType() -> PostgresDataType {
        .bytes(self)
    }
}

extension PostgresDataType {

    public var string: String? {
        if case let .string(value) = self {
            return value
        }
        return nil
    }

    public var int: Int? {
        if case let .int(value) = self {
            return value
        }
        return nil
    }

    public var double: Double? {
        if case let .double(value) = self {
            return value
        }
        return nil
    }

    public var isNull: Bool {
        if case .null = self {
            return true
        }
        return false

    }
    public var bytes: Data? {
        if case let .bytes(value) = self {
            return value
        }
        return nil
    }

    public var bool: Bool? {
        if case let .bool(value) = self {
            return value
        }
        return nil
    }

    public var array: [PostgresDataType]? {
        if case let .array(value) = self {
            return value
        }
        return nil
    }

    public var date: Date? {
        if case let .date(value) = self {
            return value
        }
        return nil
    }


    func convertToBinding(configuration: Configuration = .init(hasIntegerDatetimes: true)) -> Bind {
        switch self {
        case let .string(value):
            return Bind(string: value, configuration: configuration)
        case let .int(value):
            return Bind(int: value, configuration: configuration)
        case let .double(value):
            return Bind(double: value, configuration: configuration)
        case .null:
            return Bind(configuration: configuration)
        case let .bytes(value):
            return Bind(data: value, configuration: configuration)
        case let .bool(value):
            return Bind(bool: value, configuration: configuration)
        case let .array(value):
            return Bind(array: value, configuration: configuration)
        case let .date(value):
            return Bind(date: value, configuration: configuration)
        }
    }
    
    var postgresArrayElementString: String {
        switch self {
        case .null:
            return "NULL"

        case .bytes(let bytes):
            let hexString = bytes.map { $0.lowercaseHexPair }.joined()
            return "\"\\\\x\(hexString)\""

        case .bool(let bool):
            return bool ? "t" : "f"

        case .int(let number):
            return number.description

        case .double(let number):
            return number.description

        case .string(let string):
            let escapedString = string
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escapedString)\""

        case .array(let array):
            let elements = array.map { $0.postgresArrayElementString }
            return "{\(elements.joined(separator: ","))}"

        case .date(let date):
            return BinaryUtils.Formatters.timestamptz.string(from: date)
        }
    }
}
