//
// Symbol.swift
//


import Foundation

public typealias SymbolTable = Set<Symbol>

public struct Symbol: Hashable, Equatable, CustomStringConvertible {
    
    let name: String
    let kind: Kind
    
    public static func ==(lhs: Symbol, rhs: Symbol) -> Bool {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    enum Kind {
        case variable
        case constant
        case function
        case label
        case localNamespace
        case remoteNamespace
    }
    
    public var description: String {
        "\(kind) - \(name)"
    }
}

