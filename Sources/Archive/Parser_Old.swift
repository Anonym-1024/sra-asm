//
// 
//  
//
//
//

import Foundation

/*public class Parser_ {
    public init(fileType: File.FileType) {
        self.tokens = []
        self.pos = 0
        self.fileType = fileType
    }
    
    
    var tokens: [Token]
    var pos: Int
    var fileType: File.FileType
    
    
    public func parse(tokens: [Token]) throws -> AST {
        self.tokens = tokens
        pos = 0
        let top = try parseAsm()// upravit
        return .init(fileType: .asm, root: top)
    }
    
    
    // Helpers
    @discardableResult
    func popTerminal(kind: Token.Kind) throws -> Token {
        if pos < tokens.count {
            let token = tokens[pos]
            if token.kind == kind {
                pos += 1
                return token
            } else {
                let error = ParserError(line: token.line, kind: .expectedTerminalOfKind(kind))
                print(error)
                throw error
            }
        } else {
            
            throw ParserError(line: 0, kind: .outOfRange)
        }
    }
  
    @discardableResult
    func popTerminalOpt(kind: Token.Kind) -> Token? {
        
        if pos < tokens.count {
            let token = tokens[pos]
            if token.kind == kind {
                pos += 1
                return token
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    @discardableResult
    func popTerminal(_ lexeme: String) throws -> Token {
        if lexeme != "\n" {
            while pos < tokens.count, tokens[pos].lexeme == "\n" {
                pos += 1
            }
        }
        if pos < tokens.count {
            let token = tokens[pos]
            if token.lexeme == lexeme {
                pos += 1
                return token
            } else {
                let error = ParserError(line: token.line, kind: .expectedTerminal(lexeme))
                print(error)
                throw error
            }
        } else {
            throw ParserError(line: 0, kind: .outOfRange)
        }
    }
    @discardableResult
    func popTerminalOpt(_ lexeme: String) -> Token? {
        if lexeme != "\n" {
            while pos < tokens.count, tokens[pos].lexeme == "\n" {
                pos += 1
            }
        }
        if pos < tokens.count {
            let token = tokens[pos]
            if token.lexeme == lexeme {
                pos += 1
                return token
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    
    
    
    
    // ASM Parsing
    
    func parseAsm() throws -> AST.Node{
        var children = [AST.Node]()
        
        if let sections = try? parseSections() {
            children.append(sections)
        }
        
        try popTerminal(kind: .eof)
        
        return .nonTerminal(.asm, children: children)
    }
    
    
    func parseSections() throws -> AST.Node{
        var children = [AST.Node]()
        
        let section = try parseSection()
        
        children.append(section)
        
        if let newLine = popTerminalOpt("\n") {
            if let sectionsNode = try? parseSections() {
                children.append(sectionsNode)
            }
        }
        
        return .nonTerminal(.sections, children: children)
    }
    
    
    func parseSection() throws -> AST.Node{
        var children = [AST.Node]()
       
        let execNode = try parseExec()
        
        children.append(execNode)
        
        /*if let execNode = try? parseExec() {
            children.append(execNode)
        } else {
            let dataNode = try parseData()
            children.append(dataNode)
        }*/
        
        return .nonTerminal(.section, children: children)
    }
    
    
    func parseExec() throws -> AST.Node{
        var children = [AST.Node]()
        
        let exec = try popTerminal("exec")
        let execNode = AST.Node.terminal(exec)
        children.append(execNode)
        
        let leftBracket = try popTerminal("{")
        let leftBracketNode = AST.Node.terminal(leftBracket)
        children.append(leftBracketNode)
        
        if let execBlocksNode = try? parseExecBlocks() {
            children.append(execBlocksNode)
        }
        
        let rightBracket = try popTerminal("}")
        let rightBracketNode = AST.Node.terminal(rightBracket)
        children.append(rightBracketNode)
        
        return .nonTerminal(.exec, children: children)
    }
    
    
    func parseExecBlocks() throws -> AST.Node{
        var children = [AST.Node]()
        
        let execBlock = try parseExecBlock()
        children.append(execBlock)
        
        if let newLine = popTerminalOpt("\n") {
            if let execBlocksNode = try? parseExecBlocks() {
                children.append(execBlocksNode)
            }
        }
        
        return .nonTerminal(.execBlocks, children: children)
    }
    
    
    func parseExecBlock() throws -> AST.Node{
        var children = [AST.Node]()
        
        if let main = try? popTerminal("main") {
            let mainNode = AST.Node.terminal(main)
            children.append(mainNode)
            
            let leftBracket = try popTerminal("{")
            let leftBracketNode = AST.Node.terminal(leftBracket)
            children.append(leftBracketNode)
            
            if let instructionsNode = try? parseInstructions() {
                children.append(instructionsNode)
            }
            
            let rightBracket = try popTerminal("}")
            let rightBracketNode = AST.Node.terminal(rightBracket)
            children.append(rightBracketNode)
        } else {
            let identifier = try popTerminal(kind: .identifier)
            let identifierNode = AST.Node.terminal(identifier)
            children.append(identifierNode)
            
            
            var last = -1
            for i in 0...2 {
                if let leftPar = popTerminalOpt("(") {
                    if 0 > last, let link = popTerminalOpt("link") {
                        try popTerminal(":")
                        try popTerminal(kind: .identifier)
                        try popTerminal(")")
                        last = 0
                    } else if 1 > last, let funcArgumentsNode = try? parseFuncArguments() {
                        try popTerminal(")")
                        last = 1
                    } else if 2 > last, let ret = popTerminalOpt("ret") {
                        try popTerminal(":")
                        try popTerminal(kind: .identifier)
                        try popTerminal(")")
                        last = 2
                    } else {
                        let error = ParserError(line: leftPar.line, kind: .invalidFuncArguments)
                        print(error)
                        throw error
                    }
                }
            }
            
            let leftBracket = try popTerminal("{")
            let leftBracketNode = AST.Node.terminal(leftBracket)
            children.append(leftBracketNode)
            
            if let instructionsNode = try? parseInstructions() {
                children.append(instructionsNode)
            }
            
            let rightBracket = try popTerminal("}")
            let rightBracketNode = AST.Node.terminal(rightBracket)
            children.append(rightBracketNode)
        }
        
        return .nonTerminal(.execBlock, children: children)
    }
    
    
    func parseFuncArguments() throws -> AST.Node{
        var children = [AST.Node]()
        
        let funcArgumentNode = try parseFuncArgument()
        children.append(funcArgumentNode)
        
        if let comma = popTerminalOpt(",") {
            let funcArgumentsNode = try parseFuncArguments()
            children.append(funcArgumentsNode)
        }
        
        
        return .nonTerminal(.funcArguments, children: children)
    }
    
    
    func parseFuncArgument() throws -> AST.Node{
        var children = [AST.Node]()
        
        let label = try popTerminal(kind: .identifier)
        children.append(.terminal(label))
        let semicolon = try popTerminal(":")
        children.append(.terminal(semicolon))
        let value = try popTerminal(kind: .identifier)
        children.append(.terminal(value))
        
        return .nonTerminal(.funcArgument, children: children)
    }
    
    
    func parseInstructions() throws -> AST.Node{
        var children = [AST.Node]()
        
        if let instructionNode = try? parseInstruction(){
            children.append(instructionNode)
            
            if let newLine = popTerminalOpt("\n") {
                if let instructionsNode = try? parseInstructions() {
                    children.append(instructionsNode)
                }
            }
        } else {
            let labelNode = try parseLabel()
            children.append(labelNode)
            
            popTerminalOpt("\n")
            let instructionsNode = try parseInstructions()
            children.append(instructionsNode)
            
        }
        
        return .nonTerminal(.instructions, children: children)
    }
    
    
    func parseInstruction() throws -> AST.Node{
        var children = [AST.Node]()
        
        let instruction = try popTerminal(kind: .instruction)
        children.append(.terminal(instruction))
        
        if let argumentsNode = try? parseArguments() {
            children.append(argumentsNode)
        }
        
        return .nonTerminal(.instruction, children: children)
    }
    
    func parseLabel() throws -> AST.Node{
        var children = [AST.Node]()
        
        let label = try popTerminal(kind: .identifier)
        children.append(.terminal(label))
        
        let semicolon = try popTerminal(":")
        children.append(.terminal(semicolon))
        
        return .nonTerminal(.label, children: children)
    }
    
    func parseArguments() throws -> AST.Node{
        var children = [AST.Node]()
        
        
        
        return .nonTerminal(.arguments, children: children)
    }
    
    func parseArgument() throws -> AST.Node{
        var children = [AST.Node]()
        
        
        
        return .nonTerminal(.argument, children: children)
    }
    
    func parseImmediate() throws -> AST.Node{
        var children = [AST.Node]()
        
        
        
        return .nonTerminal(.asm, children: children)
    }
    
    
    
    func parseData() throws -> AST.Node{
        var children = [AST.Node]()
        
        
        
        return .nonTerminal(.asm, children: children)
    }
    
    func parseDataBlocks() throws -> AST.Node{
        var children = [AST.Node]()
        
        
        
        return .nonTerminal(.asm, children: children)
    }
    
    func parseDataBlock() throws -> AST.Node{
        var children = [AST.Node]()
        
        
        
        return .nonTerminal(.asm, children: children)
    }
    
    func parseVariables() throws -> AST.Node{
        var children = [AST.Node]()
        
        
        
        return .nonTerminal(.asm, children: children)
    }
    
    func parseVariable() throws -> AST.Node{
        var children = [AST.Node]()
        
        
        
        return .nonTerminal(.asm, children: children)
    }
}*/

