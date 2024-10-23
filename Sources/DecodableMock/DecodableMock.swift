import Foundation

public extension Decodable {
    static func mock(overrides: [String: Any?] = [:]) -> Self? {
        let decoder = KeyTypeDecoder(overrides: overrides)
        do {
            return try Self(from: decoder)
        } catch {
            print("Failed to initialize mock from decoder: \(error)")
            return nil
        }
    }
    
    static func mock(overrideBaseValue: Any?) -> Self? {
        .mock(overrides: ["": overrideBaseValue])
    }
}

fileprivate final class KTDHelper {
    var overrides: [String: Any?]
    
    init(overrides: [String: Any?] = [:]) {
        self.overrides = overrides
    }
    
    func valueFor(_ path: String) -> Any? {
        guard let value = overrides[path] else { return nil }
        return value
    }
    
    func decodeNilFor(_ path: String) -> Bool {
        overrides.contains { key, value in
            key == path && value == nil
        }
    }
}

fileprivate final class KeyTypeDecoder: Decoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]

    var overrideHelper: KTDHelper
    var path: String
    
    init(overrideHelper: KTDHelper, path: String) {
        self.overrideHelper = overrideHelper
        self.path = path
    }
    
    convenience init(overrides: [String: Any?] = [:]) {
        self.init(overrideHelper: .init(overrides: overrides), path: "")
    }
    
    convenience init(overrideBase value: Any?) {
        self.init(overrideHelper: .init(overrides: ["": value]), path: "")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValueContainer(baseSuperDecoder: self, overrideHelper: overrideHelper, path: path)
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        KeyedDecodingContainer(KeyedContainer<Key>(baseSuperDecoder: self, overrideHelper: overrideHelper, path: path))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        UnkeyedContainer(baseSuperDecoder: self, overrideHelper: overrideHelper, path: path)
    }
}

fileprivate final class KeyedContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    var codingPath: [CodingKey] = []
    var allKeys: [K] = []

    var baseSuperDecoder: KeyTypeDecoder
    var overrideHelper: KTDHelper
    var path: String
    
    init(baseSuperDecoder: KeyTypeDecoder, overrideHelper: KTDHelper, path: String) {
        self.baseSuperDecoder = baseSuperDecoder
        self.overrideHelper = overrideHelper
        self.path = path
    }
    
    func pathFor (_ key: K) -> String { path.isEmpty ? key.stringValue : "\(path).\(key.stringValue)" }
    func valueFor(_ key: K) -> Any?   { overrideHelper.valueFor(pathFor(key))                         }
        
    func contains(                        _ key: K)        -> Bool   { true }
    func decodeNil(                  forKey key: K) throws -> Bool   { overrideHelper.decodeNilFor(pathFor(key)) }
    func decode(_ type: Bool  .Type, forKey key: K) throws -> Bool   { valueFor(key) as? Bool   ?? false  }
    func decode(_ type: String.Type, forKey key: K) throws -> String { valueFor(key) as? String ?? "mock" }
    func decode(_ type: Double.Type, forKey key: K) throws -> Double { valueFor(key) as? Double ?? 0.0    }
    func decode(_ type: Float .Type, forKey key: K) throws -> Float  { valueFor(key) as? Float  ?? 0.0    }
    func decode(_ type: Int   .Type, forKey key: K) throws -> Int    { valueFor(key) as? Int    ?? 0      }

    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        try T(from: KeyTypeDecoder(overrideHelper: overrideHelper, path: pathFor(key)))
    }
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> {
        KeyedDecodingContainer(KeyedContainer<NestedKey>(baseSuperDecoder: baseSuperDecoder, overrideHelper: overrideHelper, path: pathFor(key)))
    }
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        UnkeyedContainer(baseSuperDecoder: baseSuperDecoder, overrideHelper: overrideHelper, path: pathFor(key))
    }

    func superDecoder(             ) throws -> Decoder { baseSuperDecoder }
    func superDecoder(forKey key: K) throws -> Decoder { baseSuperDecoder }
}

fileprivate final class SingleValueContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey] = []

    var baseSuperDecoder: KeyTypeDecoder
    var overrideHelper: KTDHelper
    var path: String
    
    init(baseSuperDecoder: KeyTypeDecoder, overrideHelper: KTDHelper, path: String) {
        self.baseSuperDecoder = baseSuperDecoder
        self.overrideHelper = overrideHelper
        self.path = path
    }

    func overrideValue()                    -> Any?   { overrideHelper.valueFor(path)        }
    func decodeNil(                )        -> Bool   { overrideHelper.decodeNilFor(path)    }
    func decode(_ type: Bool  .Type) throws -> Bool   { overrideValue() as? Bool   ?? false  }
    func decode(_ type: String.Type) throws -> String { overrideValue() as? String ?? "mock" }
    func decode(_ type: Double.Type) throws -> Double { overrideValue() as? Double ?? 0.0    }
    func decode(_ type: Float .Type) throws -> Float  { overrideValue() as? Float  ?? 0.0    }
    func decode(_ type: Int   .Type) throws -> Int    { overrideValue() as? Int    ?? 0      }
    func decode(_ type: Int8  .Type) throws -> Int8   { overrideValue() as? Int8   ?? 0      }
    func decode(_ type: Int16 .Type) throws -> Int16  { overrideValue() as? Int16  ?? 0      }
    func decode(_ type: Int32 .Type) throws -> Int32  { overrideValue() as? Int32  ?? 0      }
    func decode(_ type: Int64 .Type) throws -> Int64  { overrideValue() as? Int64  ?? 0      }
    func decode(_ type: UInt  .Type) throws -> UInt   { overrideValue() as? UInt   ?? 0      }
    func decode(_ type: UInt8 .Type) throws -> UInt8  { overrideValue() as? UInt8  ?? 0      }
    func decode(_ type: UInt16.Type) throws -> UInt16 { overrideValue() as? UInt16 ?? 0      }
    func decode(_ type: UInt32.Type) throws -> UInt32 { overrideValue() as? UInt32 ?? 0      }
    func decode(_ type: UInt64.Type) throws -> UInt64 { overrideValue() as? UInt64 ?? 0      }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if let specialType = handleSpecialTypes(type) {
            return specialType
        }
        return try T(from: KeyTypeDecoder(overrideHelper: overrideHelper, path: path))
    }
    
    private func handleSpecialTypes<T>(_ type: T.Type) -> T? where T : Decodable {
        let overrideValue = overrideValue()
        
        if let overrideValue = overrideValue as? T {
            return overrideValue
        } else if type is Decimal.Type {
            let decimal: Decimal
            if let double = overrideValue as? Double {
                decimal = .init(double)
            } else if let int = overrideValue as? Int {
                decimal = .init(Double(int))
            } else {
                decimal = .zero
            }
            return decimal as? T
        }
        return nil
    }
}

fileprivate final class UnkeyedContainer: UnkeyedDecodingContainer {
    var codingPath: [CodingKey] = []
    var count: Int?
    var currentIndex: Int = 0
    var isAtEnd: Bool { currentIndex >= count ?? 0 }

    var baseSuperDecoder: KeyTypeDecoder
    var overrideHelper: KTDHelper
    var path: String
    
    init(baseSuperDecoder: KeyTypeDecoder, overrideHelper: KTDHelper, path: String) {
        self.baseSuperDecoder = baseSuperDecoder
        self.overrideHelper = overrideHelper
        self.path = path
        
        self.count = overrideHelper.valueFor(path + "[]") as? Int ?? 1
    }

    private var elementPath: String        { path + "[\(currentIndex - 1)]" }
    private func elementValue() -> Any?    { overrideHelper.valueFor(elementPath) }
    private func increment()               { currentIndex += 1 }

    func decodeNil(                ) throws -> Bool   { increment(); return overrideHelper.decodeNilFor(elementPath) }
    func decode(_ type: Bool  .Type) throws -> Bool   { increment(); return elementValue() as? Bool   ?? false  }
    func decode(_ type: String.Type) throws -> String { increment(); return elementValue() as? String ?? "mock" }
    func decode(_ type: Double.Type) throws -> Double { increment(); return elementValue() as? Double ?? 0.0    }
    func decode(_ type: Float .Type) throws -> Float  { increment(); return elementValue() as? Float  ?? 0.0    }
    func decode(_ type: Int   .Type) throws -> Int    { increment(); return elementValue() as? Int    ?? 0      }

    func decode<T>(_ type: T  .Type) throws -> T where T : Decodable {
        increment()
        return try T(from: KeyTypeDecoder(overrideHelper: overrideHelper, path: elementPath))
    }
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        increment()
        return KeyedDecodingContainer(KeyedContainer<NestedKey>(baseSuperDecoder: baseSuperDecoder, overrideHelper: overrideHelper, path: elementPath))
    }
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        increment()
        return UnkeyedContainer(baseSuperDecoder: baseSuperDecoder, overrideHelper: overrideHelper, path: elementPath)
    }

    func superDecoder() throws -> Decoder { baseSuperDecoder }
}
