//
// Library.swift
//


import Foundation

public struct Library {
    public init(name: String, symbolTable: SymbolTable, binary: Binary) {
        self.name = name
        self.symbolTable = symbolTable
        self.binary = binary
    }
    
    let name: String
    let symbolTable: SymbolTable // Table of defined symbols
    let binary: Binary // Compiled binary
    //let binaryMap: BinaryMap // Maps symbols to address
}


