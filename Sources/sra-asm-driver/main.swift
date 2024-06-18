//
//  Driver.swift
//  
//
//
//

import ArgumentParser
import Foundation
import sra_asm


let g = File(url: .init(fileURLWithPath: "/Users/vasik/Desktop/kopec_"), fileType: .asm)
let h = try Lexer().tokenize(file: g)
var f = Parser()
do {
    print(try f.parse(h, of: .asm).strRep)
} catch {
    print(f.errors)
}



