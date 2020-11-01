//
//  Row.swift
//  
//
//  Created by Soroush Khanlou on 10/30/20.
//

import Foundation

public struct Row {
    public let fields: [String: PostgresDataType]

    public subscript(key: String) -> PostgresDataType? {
        fields[key]
    }
}
