//
// CompilerError.swift
//


import Foundation

protocol CompilerError: Error, CustomStringConvertible {
    var line: Int { get }
    var errorDescription: String { get }
    
}

extension CompilerError {
    public var description: String {
        "Line \(line): \(errorDescription)."
    }
}

