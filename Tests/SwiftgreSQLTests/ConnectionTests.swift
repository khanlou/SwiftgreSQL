import XCTest
import CPostgreSQL
@testable import SwiftgreSQL

class ConnectionTests: XCTestCase {
    static let allTests = [
        ("testConnection", testConnection),
        ("testConnInfoParams", testConnInfoParams),
        ("testConnInfoRaw", testConnInfoRaw),
        ("testConnectionFailure", testConnectionFailure),
        ("testConnectionSuccess", testConnectionSuccess),
    ]

    var postgreSQL: SwiftgreSQL.Database!

    func testConnection() throws {
        postgreSQL = SwiftgreSQL.Database.makeTest()
        let conn = try postgreSQL.makeConnection()

        let connection = try postgreSQL.makeConnection()
        XCTAssert(conn.status == CONNECTION_OK)
        XCTAssertTrue(connection.isConnected)

        try connection.reset()
        try connection.close()
        XCTAssertFalse(connection.isConnected)
    }

    func testConnInfoParams() {
        do {
            let postgreSQL = try SwiftgreSQL.Database(
                params: ["host": "127.0.0.1",
                         "port": "5432",
                         "dbname": "test",
                         "user": "postgres",
                         "password": ""])
            let conn = try postgreSQL.makeConnection()
            try conn.execute("SELECT version()")
        } catch {
            XCTFail("Could not connect to database")
        }
    }
    
    func testConnInfoRaw() {
        do {
            let postgreSQL = try SwiftgreSQL.Database(
                connInfo: "host='127.0.0.1' port='5432' dbname='test' user='postgres' password=''")
            let conn = try postgreSQL.makeConnection()
            try conn.execute("SELECT version()")
        } catch {
            XCTFail("Could not connect to database")
        }
    }

    func testConnectionFailure() throws {
        let database = try SwiftgreSQL.Database(
            hostname: "127.0.0.1",
            port: 5432,
            database: "some_long_db_name_that_does_not_exist",
            user: "postgres",
            password: ""
        )

        try XCTAssertThrowsError(database.makeConnection()) { error in
            switch error {
            case let postgreSQLError as PostgreSQLError:
                XCTAssertEqual(postgreSQLError.code, PostgreSQLError.Code.connectionFailure)
            default:
                XCTFail("Invalid error")
            }
        }
    }

    func testConnectionSuccess() throws {
        do {
            let postgreSQL = try SwiftgreSQL.Database(
                hostname: "127.0.0.1",
                port: 5432,
                database: "test",
                user: "postgres",
                password: ""
            )
            let conn = try postgreSQL.makeConnection()
            try conn.execute("SELECT version()")
        } catch {
            XCTFail("Could not connect to database")
        }
    }
}
