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
let h = try Lexer(fileType: .ash).tokenize(file: g)
var f = Parser(fileType: .ash)
f.tokens = h
do {
    print(try f.parse(h).root.stringRep(level: 0))
} catch {
    print(f.errors)
}

