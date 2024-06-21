//
//  SRADriver.swift
//  


import ArgumentParser
import Foundation
import sra_asm


let g1 = File(url: .init(fileURLWithPath: "/Users/vasik/Desktop/sra-asm/Usage/variable usage.asm"), fileType: .asm)
let g2 = File(url: .init(fileURLWithPath: "/Users/vasik/Desktop/sra-asm/Usage/untitled.asm"), fileType: .asm)
let h1 = try Lexer().tokenize(file: g1)
let h2 = try Lexer().tokenize(file: g2)
var f = Parser()

var sem = SemanticAnalyzer(in: .init(libraries: [.init(name: "knih", symbolTable: [.init(name: "prom", kind: .variable)], binary: .init())], product: .exec))
do {
    let ast1 = try f.parse(h1, of: .asm)
    let ast2 = try f.parse(h2, of: .asm)
    let ast = AST(ast1, ast2)
    print(try f.parse(h1, of: .asm).strRep)
    print("\n\n\n\n\n\n")
    let a = try ast.splitToExecAndData()
    print(a.data.stringRep(level: 0))
    
    print(sem.performSemanticAnalysis(ast).errors)
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


