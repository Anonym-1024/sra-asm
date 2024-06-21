//
//  SemanticError.swift
//  


import Foundation


public struct SemanticError: CompilerError {
    
    let kind: Kind
    let line: Int
    
    
    var errorDescription: String {
        switch kind {
        case .missingEntryPoint:
            return "Missing progrm entry point. Executable must have a \"main\" function"
        case .missingExec:
            return "Missing executable section"
        case .duplicateSymbol(let symbol):
            return "Duplicate of symbol \"\(symbol)\" found"
        case .extraneousMain:
            return "Library cannot have a \"main\" function"
        case .constWithoutValue:
            return "Constant must have assigned a value"
        case .numberOutOfRange:
            return "Number out of range"
        case .cannotAcceptImmediate:
            return "Cannot use immediate argument at this position"
        case .extraneousArgument(let expected):
            return "Extraneous argument found. Expected \(expected) arguments"
        case .missingArgument(let expected):
            return "An argument is missing. Expected \(expected) arguments"
        case .invalidRegisterName:
            return "Invalid register name"
        case .invalidSystemRegisterName:
            return "Invalid system register name"
        case .invalidPortName:
            return "Invalid port name"
        case .variableNotFound(let variable):
            return "Variable \"\(variable)\" does not exist"
        case .cannotWriteToConstant:
            return "Cannot write to a constant."
        case .missingAuxiliaryRegister:
            return "Missing auxiliary register"
        case .invalidImmediate:
            return "Invalid immediate"
        
        }
    }
    
    public enum Kind {
        case missingEntryPoint
        case missingExec
        case duplicateSymbol(String)
        case extraneousMain
        case constWithoutValue
        case numberOutOfRange
        case cannotAcceptImmediate
        case extraneousArgument(Int)
        case missingArgument(Int)
        case invalidRegisterName
        case invalidSystemRegisterName
        case invalidPortName
        case variableNotFound(String)
        case cannotWriteToConstant
        case missingAuxiliaryRegister
        case invalidImmediate
    }
    
}
