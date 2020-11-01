import XCTest
@testable import SwiftgreSQL

class ArrayTests: XCTestCase {
    static let allTests = [
        ("testIntArray", testIntArray),
        ("testStringArray", testStringArray),
        ("testBoolArray", testBoolArray),
        ("testBytesArray", testBytesArray),
        ("testUnsupportedObjectArray", testUnsupportedObjectArray),
        ("test2DArray", test2DArray),
        ("testArrayWithNull", testArrayWithNull),
    ]
    
    var postgreSQL: SwiftgreSQL.Database!

    override func setUp() {
        postgreSQL = SwiftgreSQL.Database.makeTest()
    }
    
    func testIntArray() throws {
        let conn = try postgreSQL.makeConnection()

        let rows = [
            [1,2,3,4,5],
            [123],
            [],
            [-1,2,-3,4,-5],
            [-1,2,-3,4,-5,-1,2,-3,4,-5,-1,2,-3,4,-5,-1,2,-3,4,-5],
        ]

        try conn.execute("DROP TABLE IF EXISTS foo")
        try conn.execute("CREATE TABLE foo (id serial, int_array int[])")
        for row in rows {
            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [row])
        }

        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC")
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let intArray = resultRow["int_array"]
            XCTAssertNotNil(intArray?.array)
            XCTAssertEqual(intArray!.array!.compactMap { $0.int }, rows[i])
        }
    }
    
    func testStringArray() throws {
        let conn = try postgreSQL.makeConnection()

        let rows = [
            ["A simple test string", "Another string", "", "Great testing skills"],
            [""],
            [],
            ["Server-side Swift is amazing 🤖"],
            ["🙀", "👽", "👀", "🐶", "🐱", "😂", "👻", "👍", "🙉"],
        ]

        try conn.execute("DROP TABLE IF EXISTS foo")
        try conn.execute("CREATE TABLE foo (id serial, string_array text[])")
        for row in rows {
            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [row])
        }

        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC")
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let stringArray = resultRow["string_array"]
            XCTAssertNotNil(stringArray?.array)
            XCTAssertEqual(stringArray!.array!.compactMap { $0.string }, rows[i])
        }
    }
    
    func testBoolArray() throws {
        let conn = try postgreSQL.makeConnection()

        let rows = [
            [true, false, true, true, false],
            [false],
            [],
            [true],
            [true, true, true],
            [false, true],
        ]

        try conn.execute("DROP TABLE IF EXISTS foo")
        try conn.execute("CREATE TABLE foo (id serial, bool_array bool[])")
        for row in rows {
            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", values: [.array(row.map({ .bool($0) }))])
        }

        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC")
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let boolArray = resultRow["bool_array"]
            XCTAssertNotNil(boolArray?.array)
            XCTAssertEqual(boolArray!.array!.compactMap { $0.bool }, rows[i])
        }
    }
    
    func testBytesArray() throws {
        let conn = try postgreSQL.makeConnection()

        let rows: [[PostgresDataType]] = [
            [.bytes(Data([0x00, 0x12, 0x00])), .bytes(Data([])), .bytes(Data([0x12, 0x54, 0x1f, 0xaa, 0x9a, 0xa8, 0xcd])), .bytes(Data([0x00]))],
            [.bytes(Data([0x12, 0x34, 0x56, 0x78, 0x9A]))],
            [],
            [.bytes(Data([0x98, 0x76]))],
            [.bytes(Data([0x11, 0x00])), .bytes(Data([0x22])), .bytes(Data([0x33])), .bytes(Data([0x44])), .bytes(Data([0x55]))],
        ]

        try conn.execute("DROP TABLE IF EXISTS foo")
        try conn.execute("CREATE TABLE foo (id serial, byte_array bytea[])")
        for row in rows {
            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", values: [.array(row)])
        }

        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC")
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let byteArray = resultRow["byte_array"]
            XCTAssertNotNil(byteArray?.array)
            XCTAssertEqual(byteArray?.array.flatMap { node in
                return node
            }, rows[i])
        }
    }
    
    func testUnsupportedObjectArray() throws {
//        let conn = try postgreSQL.makeConnection()
//
//        let rows: [[[String:Int]]] = [
//            [["key":1],["key":2],["key":3],["key":4],["key":5]],
//            [["key":123]],
//            [],
//            [[:]],
//            [["key":-1],["key":2],["key":-3],["key":4],["key":-5]],
//        ]
//
//        try conn.execute("DROP TABLE IF EXISTS foo")
//        try conn.execute("CREATE TABLE foo (id serial, int_array int[])")
//        for row in rows {
//            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [row.map { try $0 }])
//        }
//
//        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC")
//        XCTAssertEqual(result.count, rows.count)
//        for (i, resultRow) in result.enumerated() {
//            let intArray = resultRow["int_array"]
//            XCTAssertNotNil(intArray?.array)
//            XCTAssertEqual(intArray!.array!.count, rows[i].count)
//            XCTAssertEqual(intArray!.array!.flatMap { $0.int }, [])
//            XCTAssertEqual(intArray!.array!.flatMap { $0.isNull ? Node.null : nil }.count, rows[i].count)
//        }
    }
    
    func test2DArray() throws {
        let conn = try postgreSQL.makeConnection()

        let rows = [
            [[1, 2], [3, 4], [5, 6]],
            [[1], [2], [3], [4]],
            [],
            [[1, 2, 3]],
            [[1, 2, 3, 4], [5, 6, 7, 8]],
        ]

        try conn.execute("DROP TABLE IF EXISTS foo")
        try conn.execute("CREATE TABLE foo (id serial, int_array int[][])")
        for row in rows {
            let node = PostgresDataType.array(row.map({ .array($0.map({ .int($0) })) }))

            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", values: [node])
        }

        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC")
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let intArray = resultRow["int_array"]
            XCTAssertNotNil(intArray?.array)

            let result = intArray!.array!.compactMap { $0.array?.compactMap { $0.int } }
            for (i, rowArray) in rows[i].enumerated() {
                XCTAssertEqual(result[i], rowArray)
            }
        }
    }
    
    func testArrayWithNull() throws {
        let conn = try postgreSQL.makeConnection()

        let rows: [[PostgresDataType]] = [
            [.int(1),  .null, .int(3), .int(4), .int(5)],
            [.int(123)],
            [],
            [.int(-1),.int(2), .null,.int(4),.int(-5)],
            [.int(-1), .int(2), .int(-3), .null, .int(-5), .int(-1), .int(2), .int(-3),.int(4), .null, .int(-1), .int(2), .int(-3), .null, .int(-5), .int(-1), .int(2), .int(-3), .int(4), .int(-5)],
            [.null],
        ]

        try conn.execute("DROP TABLE IF EXISTS foo")
        try conn.execute("CREATE TABLE foo (id serial, int_array int[])")
        for row in rows {
            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", values: [.array(row)])
        }

        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC")
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let intArray = resultRow["int_array"]
            XCTAssertNotNil(intArray?.array)
            XCTAssertEqual(intArray!.array!, rows[i])
        }
    }
}
