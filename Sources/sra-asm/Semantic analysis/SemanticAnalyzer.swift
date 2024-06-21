//
//  SemanticAnalyzer.swift
//  


import Foundation


/// Semantic analyzer
public class SemanticAnalyzer {
    
    public init(in context: CompilerContext) {
        self.context = context
    }
    
    
    var context: CompilerContext
    
    var symbolTable: SymbolTable!
    var ast: AST!
    var exec: AST.Node!
    var data: AST.Node!
    
    
    /// Performs semantic analysis of an ast of asm file
    /// - Parameter ast: AST to be analyzed
    /// - Returns: returns errors found
    ///
    public func performSemanticAnalysis(_ ast: AST) -> (success: Bool, errors: [SemanticError]) {
        guard ast.root.nonterminal == .asm else { fatalError("Semantic analysis only works for asm file") }
        
        var errors = [SemanticError]()
        
        self.ast = ast
        
        
        // Split to exec, data
        do {
            let components = try ast.splitToExecAndData()
            self.exec = components.exec
            self.data = components.data
        } catch {
            errors.append(error as! SemanticError)
            
            return (success: false, errors: errors)
        }
        
        
        // check neccessary functions
        if context.product == .exec, !self.exec.children![0].children!.contains(where: { node in
            node.children![0].terminal!.lexeme == "main"
        }) {
            errors.append(.init(kind: .missingEntryPoint, line: 0))
        }
        
        // Generate symbol tables
        do {
            self.symbolTable = try generateSymbolTable()
        } catch {
            errors.append(error as! SemanticError)
            
            return (success: false, errors: errors)
        }
        
        // Add remote symbols
        for library in context.libraries {
            self.symbolTable.append(library.symbolTable, name: library.name)
        }
        
        
        // Analyze variables
        let dataBlocksNode = data.children![0]
        
        for dataBlockNode in dataBlocksNode.children! {
            if dataBlockNode.children![0].nonterminal == .variables {
                errors.append(contentsOf: analyzeVariables(dataBlockNode.children![0]))
            } else {
                errors.append(contentsOf: analyzeVariables(dataBlockNode.children![1]))
            }
        }
        
        
        
        // Analyze functions
        let functionsNode = exec.children![0]
        
        for functionNode in functionsNode.children! {
            errors.append(contentsOf: analyzeFunction(functionNode))
        }
        
        
        
        return (success: errors.isEmpty, errors: errors)
    }
    
    
    
    
 
    
    
    /// Generate symbol table of an AST exec and data sections. Check for duplicate symbols
    /// - Parameter exec: exec node
    /// - Parameter data: data node
    /// - Returns: Generated symbol table
    /// - Throws: Throws SemanticError when duplicate symbol is found
    public func generateSymbolTable() throws -> SymbolTable {
        var symbolTable: SymbolTable = []
        
        guard data.nonterminal == .data, exec.nonterminal == .exec else { fatalError("invalid Non-terminas") }
        
    
        let functionsNode = exec.children![0]
        
        for function in functionsNode.children! {
            try insertFunctionSymbols(function, to: &symbolTable)
        }
        
        
        
        let dataBlocksNode = data.children![0]
        
        for dataBlock in dataBlocksNode.children! {
            if dataBlock.children![0].nonterminal == .variables {
                try insertDataSymbols(dataBlock.children![0], to: &symbolTable)
            } else {
                try insertDataSymbols(dataBlock.children![1], in: dataBlock.children![0].terminal!.lexeme, to: &symbolTable)
            }
        }
        
        return symbolTable
    }
    
    /// Inserts symbols found in a function while checking for duplicates
    func insertFunctionSymbols(_ functionNode: AST.Node, to symbolTable: inout SymbolTable) throws {
        
        // Function name
        let functionName = functionNode.children![0].terminal!.lexeme
        if symbolTable.update(with: .init(name: functionName, kind: .function)) != nil {
            throw SemanticError(kind: .duplicateSymbol(functionNode.children![0].terminal!.lexeme), line: functionNode.children![0].terminal!.line)
        }
        
        // Labels
        let instructionsNode = functionNode.children![1]
        
        for instruction in instructionsNode.children! {
            if instruction.children![0].nonterminal == .label {
                let labelNode = instruction.children![0]
                let label = labelNode.children![0].terminal!.lexeme
                if symbolTable.update(with: .init(name: functionName + "." +  label, kind: .label)) != nil {
                    throw SemanticError(kind: .duplicateSymbol(functionName + "." +  label), line: labelNode.children![0].terminal!.line)
                }
            }
        }
    }
    
    
    /// Inserts symbols found in variables node while checking for duplicates
    func insertDataSymbols(_ variablesNode: AST.Node, in scope: String? = nil, to symbolTable: inout SymbolTable) throws {
        let scopeString = scope == nil ? "" : "\(scope!)."
        
        for variable in variablesNode.children! {
            if variable.children![0].terminal!.lexeme == "const" {
                let variableName = variable.children![1].terminal!.lexeme
                if symbolTable.update(with: .init(name: scopeString + variableName, kind: .constant)) != nil {
                    throw SemanticError(kind: .duplicateSymbol(scopeString + variableName), line: variable.children![1].terminal!.line)
                }
            } else {
                let variableName = variable.children![0].terminal!.lexeme
                if symbolTable.update(with: .init(name: scopeString + variableName, kind: .variable)) != nil {
                    throw SemanticError(kind: .duplicateSymbol(scopeString + variableName), line: variable.children![1].terminal!.line)
                }
            }
        }
    }
    
    /// Analyze variables
    func analyzeVariables(_ variablesNode: AST.Node) -> [SemanticError] {
        var errors = [SemanticError]()
        
        for variable in variablesNode.children! {
            let children = variable.children!
            
            if children[0].terminal?.lexeme == "const" {
                if children.count < 4 {
                    errors.append(.init(kind: .constWithoutValue, line: children[0].terminal!.line))
                }
            }
            
            if children.count == 4, children[3].terminal?.kind == .numericLiteral {
                var numberString = children[3].terminal!.lexeme
                
                var negative = false
                if numberString.hasPrefix("-") {
                    negative = true
                    numberString.removeFirst()
                }
                
                let radixString = numberString[numberString.startIndex...numberString.index(numberString.startIndex, offsetBy: 1)]
                
                numberString.removeFirst(2)
                
                
                var number: Int = 0
                
                switch radixString {
                case "0d":
                    number = Int(numberString, radix: 10)! * (negative ? -1 : 1)
                    
                case "0b":
                    number = Int(numberString, radix: 2)! * (negative ? -1 : 1)
                    
                case "0o":
                    number = Int(numberString, radix: 8)! * (negative ? -1 : 1)
                    
                case "0x":
                    number = Int(numberString, radix: 16)! * (negative ? -1 : 1)
                    
                default:
                    break;
                }
                
                if !Resources.validNumberRange.contains(Decimal(number))  {
                    errors.append(.init(kind: .numberOutOfRange, line: children[0].terminal!.line))
                }
            }
        }
        
        return errors
    }
    
    
    /// Analyze function
    func analyzeFunction(_ functionNode: AST.Node) -> [SemanticError] {
        var errors = [SemanticError]()
        
        let instructionsNode = functionNode.children![1]
        
        for instructionNode in instructionsNode.children! {
            errors.append(contentsOf: checkInstruction(instructionNode, in: functionNode.children![0].terminal!.lexeme))
        }
        
        return errors
    }
    
    
    /// Check instruction
    func checkInstruction(_ instructionNode_: AST.Node, in scope: String) -> [SemanticError] {
        var errors = [SemanticError]()
        
        var instructionNode = instructionNode_
        
        // Remove label
        if instructionNode.children![0].nonterminal == .label {
            instructionNode.children!.removeFirst()
        }
        
        
        var instruction = instructionNode.children![0].terminal!.lexeme
        let line = instructionNode.children![0].terminal!.line
        
        if instruction.hasPrefix("br") || instruction.hasPrefix("ba") {
            instruction = String(instruction[instruction.startIndex...instruction.index(instruction.startIndex, offsetBy: 1)])
        }
        
        if instruction.hasPrefix("brl") || instruction.hasPrefix("bal") {
            instruction = String(instruction[instruction.startIndex...instruction.index(instruction.startIndex, offsetBy: 2)])
        }
        
        var expectedArguments = Resources.instructionFormat()[instruction]!
        
        let argumentsNode = instructionNode.children![1]
        let argumentNodes = argumentsNode.children!
        
        
        // Check for correct arg count
        
        if argumentNodes.count < expectedArguments.count {
            errors.append(.init(kind: .missingArgument(expectedArguments.count), line: line))
            return errors
        } else if argumentNodes.count > expectedArguments.count {
            print(argumentNodes)
            errors.append(.init(kind: .extraneousArgument(expectedArguments.count), line: line))
            return errors
        }
        
        
        // Check arg format is matching
        for i in 0..<argumentNodes.count {
            let arg = argumentNodes[i]
            switch expectedArguments[i] {
            case .destinationRegister:
                if arg.children![0].nonterminal == .immediate {
                    errors.append(.init(kind: .cannotAcceptImmediate, line: line))
                } else if arg.children![0].children!.count != 1 || !Resources.validRegisterNames.contains(arg.children![0].children![0].terminal!.lexeme) {
                    errors.append(.init(kind: .invalidRegisterName, line: line))
                }
                
            case .sourceRegister:
                if arg.children![0].nonterminal == .immediate {
                    errors.append(.init(kind: .cannotAcceptImmediate, line: line))
                } else if arg.children![0].children!.count != 1 || !Resources.validRegisterNames.contains(arg.children![0].children![0].terminal!.lexeme){
                    if let error = isValidVariable(arg.children![0], instruction, at: i, in: scope) {
                        errors.append(.init(kind: error, line: line))
                    }
                }
                
            case .port:
                if arg.children![0].nonterminal == .immediate {
                    errors.append(.init(kind: .cannotAcceptImmediate, line: line))
                } else if arg.children![0].children!.count != 1 || !Resources.validPortNames.contains(arg.children![0].children![0].terminal!.lexeme) {
                    errors.append(.init(kind: .invalidPortName, line: line))
                }
                
            case .systemRegister:
                if arg.children![0].nonterminal == .immediate {
                    errors.append(.init(kind: .cannotAcceptImmediate, line: line))
                } else if arg.children![0].children!.count != 1 || !Resources.validSystemRegisterNames.contains(arg.children![0].children![0].terminal!.lexeme) {
                    errors.append(.init(kind: .invalidSystemRegisterName, line: line))
                }
                
            case .immediateOrSourceRegister:
                if arg.children![0].nonterminal == .immediate, let error = isImmediateVariable(arg.children![0])  {
                    errors.append(.init(kind: error, line: line))
                } else if arg.children![0].nonterminal == .location, arg.children![0].children!.count != 1 || !Resources.validRegisterNames.contains(arg.children![0].children![0].terminal!.lexeme){
                    if let error = isValidVariable(arg.children![0], instruction, at: i, in: scope) {
                        errors.append(.init(kind: error, line: line))
                    }
                }
            }
        }
        
        
        return errors
    }
    
    func variableName(_ location_: AST.Node) -> String {
        var location = location_
        var string = ""
        
        if location.children?.first?.terminal?.lexeme == "#" {
            location.children?.removeFirst()
        }
        
        if location.children?.last?.terminal?.lexeme ==  "]" {
            location.children?.removeLast(3)
        }
        
        for str in location.children! {
            string.append(str.terminal!.lexeme + ".")
        }
        
        if string.hasSuffix(".") {
            string.removeLast()
        }
        
        
        return string
    }
    
    func isValidVariable(_ location: AST.Node, _ instruction: String, at pos: Int, in scope: String) -> SemanticError.Kind? {
        
        let name = variableName(location)
        
        if !symbolTable.contains(where: { symbol in
            symbol.name == name || (symbol.kind == .label && symbol.name == scope + "." + name)
        }) {
            return .variableNotFound(name)
        }
        
        if symbolTable.first(where: { symbol in
            symbol.name == name
        })?.kind == .constant, instruction == "str", pos == 0 {
            return .cannotWriteToConstant
        }
        
        if !(location.children!.last?.terminal?.lexeme == "]") && !["mov", "mvn", "ldr"].contains(instruction) {
            return .missingAuxiliaryRegister
        }
        
        
        if !["mov", "mvn", "ldr"].contains(instruction), !Resources.validRegisterNames.contains(location.children![location.children!.count - 2].terminal!.lexeme) {
            return .missingAuxiliaryRegister
        }
        
        return nil
        
    }
    
    
    func isImmediateVariable(_ immediate: AST.Node) -> SemanticError.Kind? {
        var numberString = immediate.children![1].terminal!.lexeme
        
        if immediate.children![1].terminal?.kind == .numericLiteral {
            var negative = false
            if numberString.hasPrefix("-") {
                negative = true
                numberString.removeFirst()
            }
            
            let radixString = numberString[numberString.startIndex...numberString.index(numberString.startIndex, offsetBy: 1)]
            
            numberString.removeFirst(2)
            
            
            var number: Int = 0
            
            switch radixString {
            case "0d":
                number = Int(numberString, radix: 10)! * (negative ? -1 : 1)
                
            case "0b":
                number = Int(numberString, radix: 2)! * (negative ? -1 : 1)
                
            case "0o":
                number = Int(numberString, radix: 8)! * (negative ? -1 : 1)
                
            case "0x":
                number = Int(numberString, radix: 16)! * (negative ? -1 : 1)
                
            default:
                break;
            }
            
            if !(0...255).contains(number)  {
                return .invalidImmediate
            }
            
            if !["0", "1", "2", "3"].contains(immediate.children![2].terminal!.lexeme.dropFirst(2)) {
                return .invalidImmediate
            }
        }
        
        return nil
        
    }
    
    
    enum InstructionArgumentKind: String {
        case destinationRegister = "rd"
        case sourceRegister = "rs"
        case port = "p"
        case systemRegister = "sr"
        case immediateOrSourceRegister = "ri"
    }
}






extension Set where Element == Symbol {
    
    mutating func append(_ remote: SymbolTable, name: String) {
        for newSymbol in remote {
            self.insert(.init(name: name + newSymbol.name, kind: newSymbol.kind))
        }
    }
    
}
