
# SwiftgreSQL

This is a PostgreSQL library for Swift, generally designed to be used on the server with no dependencies. Queries are blocking.

It is forked from [vapor-community/postgresql](https://github.com/vapor-community/postgresql).

## Prerequisites

The PostgreSQL C driver must be installed in order to use this package. Follow the [README of the cpostgresql repo](https://github.com/vapor-community/cpostgresql/blob/master/README.md) to get started.

## Installing PostgreSQL

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        .package(url: "https://github.com/khanlou/SwiftgresQL", from: "0.1.0"),
    ],
    exclude: [ ... ]
)
```

## Examples

### Connecting to the Database

```swift
import PostgreSQL

let postgreSQL =  PostgreSQL.Database(
    hostname: "localhost",
    database: "test",
    user: "root",
    password: ""
)
```

### Select

```swift
let version = try postgreSQL.execute("SELECT version()")
```

### Prepared Statement

The second parameter to `execute()` is an array of `PostgresDataType` values.

```swift
let results = try postgreSQL.execute("SELECT * FROM users WHERE age >= $1", values: [.int(21)])
```

You can also pass in `PostgresDataTypeConvertible` values, which will create `PostgresDataType` values from common stdlib and Foundation types.

```swift
let results = try postgreSQL.execute("SELECT * FROM users WHERE age >= $1", [21])
```

### Listen and Notify

```swift
try postgreSQL.listen(to: "test_channel") { notification in
    print(notification.channel)
    print(notification.payload)
}

// Allow set up time for LISTEN
sleep(1)

try postgreSQL.notify(channel: "test_channel", payload: "test_payload")

```

### Connection

Each call to `execute()` creates a new connection to the PostgreSQL database. This ensures thread safety since a single connection cannot be used on more than one thread.

If you would like to re-use a connection between calls to execute, create a reusable connection and pass it as the third parameter to `execute()`.

```swift
let connection = try postgreSQL.makeConnection()
let result = try postgreSQL.execute("SELECT * FROM users WHERE age >= $1", [.int(21)]), connection)
```

### Contributors

Maintained by [Soroush Khanlou](https://github.com/khanlou), with thanks to the Vapor community for the original code..
