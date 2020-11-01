//
//  Row.swift
//  
//
//  Created by Soroush Khanlou on 10/30/20.
//

import Foundation

public struct Row {
    let fields: [String: PostgresDataType]

    subscript(key: String) -> PostgresDataType? {
        fields[key]
    }
}
