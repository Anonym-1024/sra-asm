//
//  SemanticAnalyzer.swift
//  


import Foundation


/// Semantic analyzer
public class SemanticAnalyzer {
    
    public init(for product: Header.Product) {
        self.product = product
    }
    
    
    var product: Header.Product
    
    
    /// Separate exec and data sections
    public func splitToExecAndData(ast: AST) -> (exec: AST.Node, data: AST.Node) {
        
        guard ast.fileType == .asm, ast.root.nonterminal == .asm else { fatalError("Invalid file type") }
        
        var exec = AST.Node.nonTerminal(.exec, children: [])
        var data = AST.Node.nonTerminal(.data, children: [])
        
        let asmNode = ast.root
        let sectionsNode = asmNode.children![0]
        
        for sectionNode in sectionsNode.children! {
            if sectionNode.children![0].nonterminal == .exec {
                exec.children!.append(contentsOf: sectionNode.children![0].children!)
            } else if sectionNode.children![0].nonterminal == .data {
                data.children!.append(contentsOf: sectionNode.children![0].children!)
            }
        }
        
        return (exec: exec, data: data)
    }
    
    
    /// Generate symbol table of an AST exec and data sections. Check for duplicate symbols
    /// - Parameter exec: exec node
    /// - Parameter data: data node
    /// - Returns: Generated symbol table
    /// - Throws: Throws SemanticError when duplicate symbol is found
    public func generateSymbolTable(exec: AST.Node, data: AST.Node) throws -> SymbolTable {
        var symbolTable: SymbolTable = []
        
        guard data.nonterminal == .data, exec.nonterminal == .exec else { fatalError("invalid Non-terminas") }
        
    
        let functionsNode = exec.children![1]
        
        for function in functionsNode.children! {
            try insertFunctionSymbols(function, to: &symbolTable)
        }
        
        
        
        let dataBlocksNode = data.children![1]
        
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
    func insertFunctionSymbols(_ function: AST.Node, to symbolTable: inout SymbolTable) throws {
        
        // Function name
        let functionName = function.children![0].terminal!.lexeme
        if symbolTable.update(with: .init(name: functionName, kind: .function)) != nil {
            throw SemanticError(kind: .duplicateSymbol(function.children![0].terminal!.lexeme), line: function.children![0].terminal!.line)
        }
        
        // Labels
        let instructionsNode = function.children![1]
        
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
    func insertDataSymbols(_ variables: AST.Node, in scope: String? = nil, to symbolTable: inout SymbolTable) throws {
        let scopeString = scope == nil ? "" : "\(scope!)."
        
        for variable in variables.children! {
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
    
    
    
    
    
    

}
