import Foundation

public final class Bind {
    private class SmartPointer {
        let bytes: UnsafeMutablePointer<Int8>
        let length: Int
        let ownsMemory: Bool
        init(bytes: UnsafeMutablePointer<Int8>, length: Int, ownsMemory: Bool) {
            self.bytes = bytes
            self.length = length
            self.ownsMemory = ownsMemory
        }

        deinit {
            if ownsMemory {
                bytes.deallocate()
            }
        }
    }

    // MARK: - Enums
    
    public enum Format : Int32 {
        case string = 0
        case binary = 1
    }
    
    // MARK: - Properties
    
    public var bytes: UnsafeMutablePointer<Int8>? {
        get {
            return buffer?.bytes
        }
    }
    public var length: Int {
        get {
            return buffer?.length ?? 0
        }
    }

    private let buffer: SmartPointer?
    
    public let type: FieldType
    public let format: Format
    
    public let configuration: Configuration
    public let result: Result?
    
    // MARK: - Init
    
    /**
     Creates a NULL input binding.
     
     PQexecParams converts nil pointer to NULL.
     see: https://www.postgresql.org/docs/9.1/static/libpq-exec.html
     */
    public init(configuration: Configuration) {
        self.configuration = configuration

        buffer = nil

        type = nil
        format = .string
        
        result = nil
    }
    
    /**
     Creates an input binding from a String.
     */
    public convenience init(string: String, configuration: Configuration) {
        let utf8CString = string.utf8CString
        let count = utf8CString.count
        
        let bytes = UnsafeMutablePointer<Int8>.allocate(capacity: count)
        for (i, char) in utf8CString.enumerated() {
            bytes[i] = char
        }
        
        self.init(bytes: bytes, length: count, ownsMemory: true, type: nil, format: .string, configuration: configuration)
    }
    
    /**
     Creates an input binding from a UInt.
     */
    public convenience init(bool: Bool, configuration: Configuration) {
        let bytes = UnsafeMutablePointer<Int8>.allocate(capacity: 1)
        bytes.initialize(to: bool ? 1 : 0)
        
        self.init(bytes: bytes, length: 1, ownsMemory: true, type: FieldType(.bool), format: .binary, configuration: configuration)
    }
    
    /**
     Creates an input binding from an Int.
     */
    public convenience init(int: Int, configuration: Configuration) {
        let count = MemoryLayout.size(ofValue: int)
        
        let type: FieldType
        switch count {
        case 2:
            type = FieldType(.int2)
        case 4:
            type = FieldType(.int4)
        case 8:
            type = FieldType(.int8)
        default:
            // Unsupported integer size, use string instead
            self.init(string: int.description, configuration: configuration)
            return
        }
        
        var value = int.bigEndian
        let (bytes, length) = BinaryUtils.valueToBytes(&value)
        self.init(bytes: bytes, length: length, ownsMemory: true, type: type, format: .binary, configuration: configuration)
    }
    
    /**
     Creates an input binding from a UInt.
     */
    public convenience init(uint: UInt, configuration: Configuration) {
        let int: Int
        if uint >= UInt(Int.max) {
            int = Int.max
        }
        else {
            int = Int(uint)
        }
        
        self.init(int: int, configuration: configuration)
    }
    
    /**
     Creates an input binding from an Double.
     */
    public convenience init(double: Double, configuration: Configuration) {
        let count = MemoryLayout.size(ofValue: double)
        
        let type: FieldType
        switch count {
        case 4:
            type = FieldType(.float4)
        case 8:
            type = FieldType(.float8)
        default:
            // Unsupported float size, use string instead
            self.init(string: double.description, configuration: configuration)
            return
        }
        
        var value = double.bigEndian
        let (bytes, length) = BinaryUtils.valueToBytes(&value)
        self.init(bytes: bytes, length: length, ownsMemory: true, type: type, format: .binary, configuration: configuration)
    }

    /**
     Creates an input binding from an array of bytes.
     */
    public convenience init(data: Data, configuration: Configuration) {
        let int8Bytes: UnsafeMutablePointer<Int8> = UnsafeMutablePointer.allocate(capacity: data.count)
        for (i, byte) in data.enumerated() {
            int8Bytes[i] = Int8(bitPattern: byte)
        }

        self.init(bytes: int8Bytes, length: data.count, ownsMemory: true, type: nil, format: .binary, configuration: configuration)
    }

    /**
     Creates an input binding from a Date.
     */
    public convenience init(date: Date, configuration: Configuration) {
        let interval = date.timeIntervalSince(BinaryUtils.TimestampConstants.referenceDate)		

        if configuration.hasIntegerDatetimes {
            let microseconds = Int64(interval * 1_000_000)
            var value = microseconds.bigEndian
            let (bytes, length) = BinaryUtils.valueToBytes(&value)
            self.init(bytes: bytes, length: length, ownsMemory: true, type: FieldType(.timestamptz), format: .binary, configuration: configuration)
        }
        else {
            let seconds = Float64(interval)
            var value = seconds.bigEndian
            let (bytes, length) = BinaryUtils.valueToBytes(&value)
            self.init(bytes: bytes, length: length, ownsMemory: true, type: FieldType(.timestamptz), format: .binary, configuration: configuration)
        }
    }
    
    /**
     Creates an input binding from an array.
     */
    public convenience init(array: [PostgresDataType], configuration: Configuration) {
        let elements = array.map { $0.postgresArrayElementString }
        let arrayString = "{\(elements.joined(separator: ","))}"
        self.init(string: arrayString, configuration: configuration)
    }

    public init(bytes: UnsafeMutablePointer<Int8>?, length: Int, ownsMemory: Bool, type: FieldType, format: Format, configuration: Configuration) {
        self.buffer = bytes.map { SmartPointer(bytes: $0, length: length, ownsMemory: ownsMemory) }

        self.type = type
        self.format = format
        
        self.configuration = configuration
        
        result = nil
    }
    
    public init(result: Result, bytes: UnsafeMutablePointer<Int8>, length: Int, ownsMemory: Bool, type: FieldType, format: Format, configuration: Configuration) {
        self.result = result

        self.buffer = SmartPointer(bytes: bytes, length: length, ownsMemory: ownsMemory)

        self.type = type
        self.format = format
        
        self.configuration = configuration
    }
}
