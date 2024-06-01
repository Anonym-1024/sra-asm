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
print(h)
print(try Parser(fileType: .asm).parse(tokens: h))

