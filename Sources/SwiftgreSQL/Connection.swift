import CPostgreSQL
import Dispatch
import Foundation

// This structure represents a handle to one database connection.
// It is used for almost all PostgreSQL functions.
// Do not try to make a copy of a PostgreSQL structure.
// There is no guarantee that such a copy will be usable.
public final class Connection: ConnInfoInitializable {
    
    // MARK: - CConnection
    
    public typealias CConnection = OpaquePointer
    
    public let cConnection: CConnection
    
    // MARK: - Init

    public init(connInfo: ConnInfo) throws {
        let string: String

        switch connInfo {
        case .raw(let info):
            string = info
        case .params(let params):
            string = params.map({ "\($0)='\($1)'" }).joined()
        case .basic(let hostname, let port, let database, let user, let password):
            string = "host='\(hostname)' port='\(port)' dbname='\(database)' user='\(user)' password='\(password)' client_encoding='UTF8'"
        }

        cConnection = PQconnectdb(string)
        try validateConnection()
    }
    
    // MARK: - Deinit
    
    deinit {
        try? close()
    }
    
    // MARK: - Execute

    @discardableResult
    public func execute(_ query: String, _ convertibles: [PostgresDataTypeConvertible] = []) throws -> [Row] {
        let binds = convertibles.map({ value -> Bind in
            value
                .convertToPostgresType()
                .convertToBinding()
        })
        return try execute(query, binds)
    }

    @discardableResult
    public func execute(_ query: String, values: [PostgresDataType]) throws -> [Row] {
        let binds = values.map({ value -> Bind in
            value
                .convertToBinding()
        })
        return try execute(query, binds)
    }

    
    @discardableResult
    public func execute(_ query: String, _ binds: [Bind]) throws -> [Row] {
        var types: [Oid] = []
        types.reserveCapacity(binds.count)
        
        var formats: [Int32] = []
        formats.reserveCapacity(binds.count)
        
        var values: [UnsafePointer<Int8>?] = []
        values.reserveCapacity(binds.count)
        
        var lengths: [Int32] = []
        lengths.reserveCapacity(binds.count)
        
        for bind in binds {
            
            types.append(bind.type.oid ?? 0)
            formats.append(bind.format.rawValue)
            values.append(bind.bytes)
            lengths.append(Int32(bind.length))
        }
        
        let resultPointer: Result.Pointer? = PQexecParams(
            cConnection,
            query,
            Int32(binds.count),
            types,
            values,
            lengths,
            formats,
            Bind.Format.binary.rawValue
        )
        
        let result = Result(pointer: resultPointer, connection: self)
        return try result.parseData()
    }
    
    // MARK: - Connection Status
    
    public var isConnected: Bool {
        return PQstatus(cConnection) == CONNECTION_OK
    }

    public var status: ConnStatusType {
        return PQstatus(cConnection)
    }
    
    private func validateConnection() throws {
        guard isConnected else {
            throw PostgreSQLError(code: .connectionFailure, connection: self)
        }
    }

    public func reset() throws {
        try validateConnection()
        PQreset(cConnection)
    }

    public func close() throws {
        try validateConnection()
        PQfinish(cConnection)
    }
    
    // MARK: - Transaction
    
    public enum TransactionIsolationLevel {
        case readCommitted
        case repeatableRead
        case serializable
        
        var sqlName: String {
            switch self {
            case .readCommitted:
                return "READ COMMITTED"
                
            case .repeatableRead:
                return "REPEATABLE READ"
                
            case .serializable:
                return "SERIALIZABLE"
            }
        }
    }
    
    public func transaction<R>(isolationLevel: TransactionIsolationLevel = .readCommitted, closure: () throws -> R) throws -> R {
        try execute("BEGIN TRANSACTION ISOLATION LEVEL \(isolationLevel.sqlName)")

        let value: R
        do {
            value = try closure()
        } catch {
            // rollback changes and then rethrow the error
            try execute("ROLLBACK")
            throw error
        }

        try execute("COMMIT")
        return value
    }
    
    // MARK: - LISTEN/NOTIFY
    
    public struct Notification {
        public let pid: Int
        public let channel: String
        public let payload: String?
        
        init(pgNotify: PGnotify) {
            channel = String(cString: pgNotify.relname)
            pid = Int(pgNotify.be_pid)
            
            if pgNotify.extra != nil {
                let string = String(cString: pgNotify.extra)
                if !string.isEmpty {
                    payload = string
                }
                else {
                    payload = nil
                }
            }
            else {
                payload = nil
            }
        }
    }
    
    /// Registers as a listener on a specific notification channel.
    ///
    /// - Parameters:
    ///   - channel: The channel to register for.
    ///   - queue: The queue to perform the listening on.
    ///   - callback: Callback containing any received notification or error and a boolean which can be set to true to stop listening.
    public func listen(toChannel channel: String, on queue: DispatchQueue = DispatchQueue.global(), callback: @escaping (Notification?, Error?, inout Bool) -> Void) {
        queue.async {
            var stop: Bool = false
            
            do {
                try self.execute("LISTEN \(channel)")

                while !stop {
                    try self.validateConnection()

                    // Sleep to avoid looping continuously on cpu
                    Thread.sleep(forTimeInterval: 1)
                    
                    PQconsumeInput(self.cConnection)

                    while !stop, let pgNotify = PQnotifies(self.cConnection) {
                        let notification = Notification(pgNotify: pgNotify.pointee)

                        callback(notification, nil, &stop)

                        PQfreemem(pgNotify)
                    }
                }
            }
            catch {
                callback(nil, error, &stop)
            }
        }
    }
    
    public func notify(channel: String, payload: String? = nil) throws {
        if let payload = payload {
            try execute("NOTIFY \(channel), '\(payload)'")
        }
        else {
            try execute("NOTIFY \(channel)")
        }
    }

    // MARK: - Configuration
    
    private var cachedConfiguration: Configuration?
    
    public var configuration: Configuration {
        if let configuration = cachedConfiguration {
            return configuration
        }
        
        let hasIntegerDatetimes = getBooleanParameterStatus(key: "integer_datetimes", default: true)
        
        let configuration = Configuration(hasIntegerDatetimes: hasIntegerDatetimes)
        cachedConfiguration = configuration
        
        return configuration
    }

    private func getBooleanParameterStatus(key: String, `default` defaultValue: Bool = false) -> Bool {
        guard let value = PQparameterStatus(cConnection, "integer_datetimes") else {
            return defaultValue
        }
        return String(cString: value) == "on"
    }
}
