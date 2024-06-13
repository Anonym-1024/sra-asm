//
//  Driver.swift
//  
//
//
//

import ArgumentParser
import Foundation
import sra_asm

let g = File(url: .init(fileURLWithPath: "/Users/vasik/Desktop/kopec_"), fileType: .ash)
let h = try Lexer(fileType: .asm).tokenize(file: g)
var f = Parser(fileType: .asm)
f.tokens = h
do {
    print(try f.parseAsm().stringRep(level: 0))
} catch {
    print(f.errors)
}

