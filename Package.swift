// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SwiftgreSQL",
    products: [
        .library(name: "SwiftgreSQL", targets: ["SwiftgreSQL"]),
    ],
    dependencies: [
        // Module map for `libpq`
        .package(name: "CPostgreSQL", url: "https://github.com/vapor-community/cpostgresql.git", from: "2.1.0"),
    ],
    targets: [
        .target(name: "SwiftgreSQL", dependencies: ["CPostgreSQL"]),
        .testTarget(name: "SwiftgreSQLTests", dependencies: ["SwiftgreSQL"]),
    ]
)
