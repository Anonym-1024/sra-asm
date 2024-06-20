//
//  SRADriver.swift
//  


import ArgumentParser
import Foundation
import sra_asm


let g = File(url: .init(fileURLWithPath: "/Users/vasik/Desktop/sra-asm/Usage/variable usage.asm"), fileType: .asm)
let h = try Lexer().tokenize(file: g)
var f = Parser()

var sem = SemanticAnalyzer(for: .exec)
do {
    let ast = try f.parse(h, of: .asm)
    print(try f.parse(h, of: .asm).strRep)
    print("\n\n\n\n\n\n")
    let a = try sem.splitToExecAndData(ast: ast)
    print(a.data.stringRep(level: 0))
    
    print(try sem.generateSymbolTable(exec: a.exec, data: a.data))
} catch {
    print(f.errors, error)
}
/*
@main
struct SRADriver: ParsableCommand {
    static var configuration: CommandConfiguration = .init(commandName: "sra", subcommands: [MakeHeader.self])
    
    func run() {
        print("Welcome to sra-asm.")
    }
}*/


