import Foundation

/// A type that is capable of being used as a dynamic route parameter.
///
///     router.get("users", Int.self) { req in
///         let id = try req.parameters.next(Int.self)
///         return "user id: \(id)"
///     }
///
/// Use the static `parameter` property to generate a `PathComponent` for this type.
public protocol Parameter {
    /// The type this parameter will convert to once it is looked up.
    /// Most types like `String` and `Int` will simply return self, but some
    /// more complex types may wish to perform async lookups or conversions to different types.
    associatedtype ResolvedParameter
    associatedtype ParameterType: LosslessDataConvertible

    /// A unique key to use for identifying this parameter in the URL.
    /// Defaults to the type name lowercased.
    static var routingSlug: String { get }

    /// Resolves an instance of the `ResolvedParameter` type for this `Parameter`
    /// based on the concrete `String` found in the URL.
    ///
    ///     dynamic path: /users/:id
    ///     actual path:  /users/42
    ///
    /// For example, in the above example the parameter string would be `"42"`.
    ///
    /// - parameters:
    ///     - parameter: Concrete `String` that has been supplied in the URL in the position
    ///       specified by this dynamic parameter.
    /// - returns: An instance of the `ResolvedParameter` type if one could be created.
    /// - throws: Throws an error if a `ResolvedParameter` could not be created.
    static func resolveParameter(_ parameter: String) throws -> ResolvedParameter
    
    /// Creates a `PathComponent` for this type which can be used
    /// when registering routes to a router.
    static var parameter: PathComponent { get }
}

// MARK: Methods

extension Parameter where Self: LosslessDataConvertible {
    public typealias ParameterType = Self
   
    /// See `Parameter`.
    public static var parameter: PathComponent {
        return .parameter(routingSlug, Self.self)
    }
}

extension Parameter {
    /// See `Parameter`.
    public static var parameter: PathComponent {
        return .parameter(routingSlug, ParameterType.self)
    }
}

// MARK: Optional Requirements

extension Parameter {
    /// See `Parameter`.
    public static var routingSlug: String {
        return "\(Self.self)".lowercased()
    }
}

// MARK: Default Types

extension String: Parameter {
    /// See `Parameter`.
    public static func resolveParameter(_ parameter: String) throws -> String {
        return parameter
    }
}

extension FixedWidthInteger {
    /// See `Parameter`.
    public static func resolveParameter(_ parameter: String) throws -> Self {
        guard let number = Self(parameter) else {
            throw RoutingError(identifier: "fwi", reason: "The parameter was not convertible to an \(Self.self)")
        }
        return number
    }
}

extension Int: Parameter, LosslessDataConvertible { }
extension Int8: Parameter, LosslessDataConvertible { }
extension Int16: Parameter, LosslessDataConvertible { }
extension Int32: Parameter, LosslessDataConvertible { }
extension Int64: Parameter, LosslessDataConvertible { }
extension UInt: Parameter, LosslessDataConvertible { }
extension UInt8: Parameter, LosslessDataConvertible { }
extension UInt16: Parameter, LosslessDataConvertible { }
extension UInt32: Parameter, LosslessDataConvertible { }
extension UInt64: Parameter, LosslessDataConvertible { }

extension BinaryFloatingPoint {
    /// See `Parameter`.
    public static func resolveParameter(_ parameter: String) throws -> Self {
        guard let number = Double(parameter) else {
            throw RoutingError(identifier: "bfp", reason: "The parameter was not convertible to a \(Self.self)")
        }

        return Self(number)
    }
}

extension Float: Parameter, LosslessDataConvertible{ }
extension Double: Parameter, LosslessDataConvertible { }

extension UUID: Parameter, LosslessDataConvertible {
    /// Attempts to read the parameter into a `UUID`
    public static func resolveParameter(_ parameter: String) throws -> UUID {
        guard let uuid = UUID(uuidString: parameter) else {
            throw RoutingError(identifier: "uuid", reason: "The parameter was not convertible to a UUID")
        }

        return uuid
    }
    
    public init?(_ data: Data) {
        guard let number = (data.withUnsafeBytes {
            (pointer: UnsafePointer<UUID>) -> UUID? in
            if MemoryLayout<UUID>.size != data.count { return nil }
            return pointer.pointee
        }) else {
            return nil
        }
        
        self = number
    }
}

