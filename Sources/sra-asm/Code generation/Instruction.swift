//
//  Instruction.swift
//  


import Foundation

struct Instruction {
    struct Argument {
        let kind: Kind
        let value: Int
        
        enum Kind {
            case register
            case port
            case systemRegister
            case immediate
        }
    }
}
