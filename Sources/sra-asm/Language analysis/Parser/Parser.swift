//
// Parser.swift
//


import Foundation



/// Syntax analyzer
public class Parser {
    
    /// Initialize a Lexer
    public init() {
        self.tokens = []
        self.pos = 0
        self.errors = []
        self.parsing = []
    }
    
    
    var tokens: [Token]
    var pos: Int
    var fileType: File.FileType!
    public var errors: [ParserError]
    
    var parsing: [AST.Node.NonTerminal]
    var line: Int {
        if pos < tokens.count {
            return tokens[pos].line
        }
        return 0
    }
    
    
    // Helpers
    
    /// Pop terminal when kind is matched while ignoring newlines
    func popTerminal(kind: Token.Kind) -> Token? {
        var _pos = pos
        while _pos < tokens.count, tokens[_pos].lexeme == "\n" {
            _pos += 1
        }
        if _pos < tokens.count {
            let token = tokens[_pos]
            if token.kind == kind {
                pos = _pos + 1
                return token
            }
        }
        return nil
    }
    
    
    /// Pop terminal when lexeme is matched while ignoring newlines
    func popTerminal(_ lexeme: String) -> Token? {
        var _pos = pos
        while _pos < tokens.count, tokens[_pos].lexeme == "\n" {
            _pos += 1
        }
        if _pos < tokens.count {
            let token = tokens[_pos]
            if token.lexeme == lexeme {
                pos = _pos + 1
                return token
            }
        }
        return nil
    }
    
    
    /// Pop newline token
    func popNewLine() -> Bool{
        if pos < tokens.count, tokens[pos].lexeme == "\n" {
            pos += 1
            return true
        }
        return false
    }
    
    
    /// Check if lookahead matches a kind
    func lookAhead(offset: Int = 0, _ kind: Token.Kind) -> Bool {
        var _pos = pos
        for _ in 0..<(offset + 1) {
            while _pos < tokens.count, tokens[_pos].lexeme == "\n" {
                _pos += 1
            }
            _pos += 1
        }
        _pos -= 1
        if _pos + offset < tokens.count {
            let token = tokens[_pos]
            return token.kind == kind
        }
        return false
    }
    
    
    /// Check if lookahead matches a lexeme
    func lookAhead(offset: Int = 0, _ lexeme: String) -> Bool {
        var _pos = pos
        for _ in 0..<(offset + 1) {
            while _pos < tokens.count, tokens[_pos].lexeme == "\n" {
                _pos += 1
            }
            _pos += 1
        }
        _pos -= 1
            
        if _pos + offset < tokens.count {
            let token = tokens[_pos]
            return token.lexeme == lexeme
        }
        return false
    }
    
    
    func error(_ kind: ParserError.Kind) -> ParserError {
        let err =  ParserError(line: line, kind: kind, parsing: parsing.last!)
        errors.append(err)
        return err
    } 
    
    
    
    
    
    /// Builds an abstract syntax tree and performs syntax analysis
    /// - Parameter tokens: Tokens to be parsed
    /// - Parameter type: File type of parsed file
    /// - Returns: Generated abstract syntax tree
    /// - Throws: Throws ParserError
    public func parse(_ tokens: [Token], of type: File.FileType) throws -> AST {
        
        self.fileType = type
        self.tokens = tokens
        self.pos = 0
        self.errors = []
        self.parsing = []
        
        
        if fileType == .asm {
            return .init(fileType: .asm, root: try parseAsm())
        } else {
            return .init(fileType: .ash, root: try parseAsh())
        }
    }
    
    
    
    
    
    // ------ Parsing ASM -------
    
    
    func parseAsm() throws -> AST.Node {
        parsing.append(.asm)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        let sections = parseSections()
        children.append(sections)
        
        guard popTerminal(kind: .eof) != nil else { throw error(.expectedTerminalOfKind(.eof)) }
    
        
        
        return .nonTerminal(.asm, children: children)
    }
    
    
    func parseSections() -> AST.Node {
        parsing.append(.sections)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if let section = try? parseSection() {
            children.append(section)
            
            while parseBreak(), let section_ = try? parseSection() {
                children.append(section_)
            }
        }
        
        
        
        
        
        return .nonTerminal(.sections, children: children)
    }
    
    
    func parseSection() throws -> AST.Node {
        
        parsing.append(.section)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
    
        if lookAhead("exec") {
            let exec = try parseExec()
            children.append(exec)
        } else if lookAhead("data") {
            let data = try parseData()
            children.append(data)
        } else {
            throw error(.expectedNonTerminal(.section))
        }
        
        
        return .nonTerminal(.section, children: children)
    }
    
    
    func parseExec() throws -> AST.Node {
        parsing.append(.exec)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let exec = popTerminal("exec") else { throw error(.expectedTerminal("exec")) }
        children.append(.terminal(exec))
        
        guard popTerminal("{") != nil else { throw error(.expectedTerminal("{")) }
        
        let functions =  parseFunctions()
        children.append(functions)
        
        guard popTerminal("}") != nil else { throw error(.expectedTerminal("}")) }
        
        
        return .nonTerminal(.exec, children: children)
    }
    
    
    func parseFunctions() -> AST.Node {
        parsing.append(.functions)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if let function = try? parseFunction() {
            children.append(function)
            
            while parseBreak(), let function_ = try? parseFunction() {
                children.append(function_)
            }
        }
        
        
        return .nonTerminal(.functions, children: children)
    }
    
    
    func parseFunction() throws -> AST.Node {
        parsing.append(.function)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if let main = popTerminal("main") {
            children.append(.terminal(main))
            
            guard popTerminal("{") != nil else { throw error(.expectedTerminal("{")) }
            
            let instructions = parseInstructions()
            children.append(instructions)
            
            guard popTerminal("}") != nil else { throw error(.expectedTerminal("}")) }
            
        } else {
            guard let identifier = popTerminal(kind: .identifier) else { throw error(.expectedTerminalOfKind(.identifier)) }
            children.append(.terminal(identifier))
            while lookAhead("(") {
                while !lookAhead(")") {
                    if pos < tokens.count {
                        pos += 1
                    } else {
                        throw error(.expectedTerminal(")"))
                    }
                }
                pos += 1
            }
            
            guard popTerminal("{") != nil else { throw error(.expectedTerminal("{")) }
            let instructions = parseInstructions()
            children.append(instructions)
            
            
            guard popTerminal("}") != nil else { throw error(.expectedTerminal("}")) }
        }
        
        
        
        
        return .nonTerminal(.function, children: children)
    }
    
    

    
    func parseLocation() throws -> AST.Node {
        parsing.append(.location)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let identifier = popTerminal(kind: .identifier) else { throw error(.expectedTerminalOfKind(.identifier)) }
        children.append(.terminal(identifier))
        
        if popTerminal(".") != nil {
            
            let location = try parseLocation()
            children.append(location)
        }
        
        return .nonTerminal(.location, children: children)
    }
    
    
    func parseInstructions() -> AST.Node {
        parsing.append(.instructions)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if let instruction = try? parseInstruction() {
            children.append(instruction)
            
            while parseBreak(), let instruction_ = try? parseInstruction() {
                children.append(instruction_)
            }
        }
        
        return .nonTerminal(.instructions, children: children)
    }
    
    
    func parseInstruction() throws -> AST.Node {
        
        parsing.append(.instruction)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if let label = try? parseLabel() {
            children.append(label)
        }
        
        
        
        guard let instruction = popTerminal(kind: .instruction) else { throw error(.invalidInstruction) }
        children.append(.terminal(instruction))
        
        let args = parseArgs()
        children.append(args)
        
        
        return .nonTerminal(.instruction, children: children)
    }
    
    
    func parseBreak() -> Bool {
        if popNewLine() {
            return true
        }
        return popTerminal(";") != nil || lookAhead("}")
    }
    
    
    func parseLabel() throws -> AST.Node {
        parsing.append(.label)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let identifier = popTerminal(kind: .identifier) else { throw error(.expectedTerminalOfKind(.identifier)) }
        children.append(.terminal(identifier))
        
        guard popTerminal(":") != nil else { throw error(.expectedTerminal(":")) }
        
        _ = popNewLine()
        
        
        return .nonTerminal(.label, children: children)
    }
    
    
    func parseArgs() -> AST.Node {
        parsing.append(.args)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if !lookAhead(offset: 1, ":"), let arg = try? parseArg() {
            children.append(arg)
            
            while popTerminal(",") != nil, let arg_ = try? parseArg() {
                children.append(arg_)
            }
        }
        
        return .nonTerminal(.args, children: children)
    }
    
    
    func parseArg() throws -> AST.Node {
        parsing.append(.arg)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if lookAhead(.identifier) {
            let location = try parseLocation()
            children.append(location)
        } else if lookAhead("#") {
            let immediate = try parseImmediate()
            children.append(immediate)
        } else {
            throw error(.expectedNonTerminal(.arg))
        }
        
        
        return .nonTerminal(.arg, children: children)
    }
    
    
    func parseImmediate() throws -> AST.Node {
        parsing.append(.immediate)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let numberSign = popTerminal("#") else { throw error(.expectedTerminal("#")) }
        children.append(.terminal(numberSign))
                                            
        guard let numericLiteral = popTerminal(kind: .numericLiteral) else { throw error(.expectedTerminalOfKind(.numericLiteral)) }
        children.append(.terminal(numericLiteral))
        
        if popTerminal("[") != nil {
            
            guard let numericLiteral_ = popTerminal(kind: .numericLiteral) else { throw error(.expectedTerminalOfKind(.numericLiteral)) }
            children.append(.terminal(numericLiteral_))
            
            guard popTerminal("]") != nil else { throw error(.expectedTerminal("]")) }
        }
        
        return .nonTerminal(.immediate, children: children)
    }
    
    
    func parseData() throws -> AST.Node {
        parsing.append(.data)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let data = popTerminal("data") else { throw error(.expectedTerminal("data")) }
        children.append(.terminal(data))
        
        guard popTerminal("{") != nil else { throw error(.expectedTerminal("{")) }
        
        let dataBlocks = parseDataBlocks()
        children.append(dataBlocks)
        
        
        guard popTerminal("}") != nil else { throw error(.expectedTerminal("}")) }
        
        return .nonTerminal(.data, children: children)
    }
    
    
    func parseDataBlocks() -> AST.Node {
        parsing.append(.dataBlocks)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if let dataBlock = try? parseDataBlock() {
            children.append(dataBlock)
            
            while let dataBlock_ = try? parseDataBlock() {
                children.append(dataBlock_)
            }
        }
        
        
        return .nonTerminal(.dataBlocks, children: children)
    }
    
    
    func parseDataBlock() throws -> AST.Node {
        parsing.append(.dataBlock)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if lookAhead(offset: 1, "{") {
            guard let identifier = popTerminal(kind: .identifier) else { throw error(.expectedTerminalOfKind(.identifier)) }
            children.append(.terminal(identifier))
            
            guard popTerminal("{") != nil else { throw error(.expectedTerminal("{")) }
            
            if let variables = try? parseVariables() {
                children.append(variables)
            }
            
            
            
            guard popTerminal("}") != nil else { throw error(.expectedTerminal("}")) }
            
            _ = parseBreak()
        } else {
            let variables = try parseVariables()
            children.append(variables)
        }
        
        return .nonTerminal(.dataBlock, children: children)
    }
    
    
    func parseVariables() throws -> AST.Node {
        
        parsing.append(.variables)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if let variable = try? parseVariable() {
            children.append(variable)
            if !parseBreak() { throw error(.expectedTerminal(";")) }
            while let variable_ = try? parseVariable() {
                
                children.append(variable_)
                if !parseBreak() { throw error(.expectedTerminal(";")) }
            }
        } else {
            throw error(.expectedNonTerminal(.variable))
        }
        
        return .nonTerminal(.variables, children: children)
    }
    
    
    func parseVariable() throws -> AST.Node {
        parsing.append(.variable)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if lookAhead(offset: 1, "{") {
            throw error(.notVariable)
        }
        
        guard let identifier = popTerminal(kind: .identifier) else { throw error(.expectedTerminalOfKind(.identifier)) }
        children.append(.terminal(identifier))
        
        
        
        if let equals = popTerminal("=") {
            children.append(.terminal(equals))
            if let numericLiteral = popTerminal(kind: .numericLiteral) {
                children.append(.terminal(numericLiteral))
            } else {
                guard let charLiteral = popTerminal(kind: .charLiteral) else { throw error(.expectedTerminalOfKind(.charLiteral))}
                children.append(.terminal(charLiteral))
            }
        }
        
        return .nonTerminal(.variable, children: children)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // ------ Parsing ASM -------
    
    
    func parseAsh() throws -> AST.Node {
        parsing.append(.ash)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        let header = try parseHeader()
        children.append(header)
        
        if let compile = try? parseCompile() {
            children.append(compile)
        }
        
        if let include = try? parseInclude() {
            children.append(include)
        }
    
        if let link = try? parseLink() {
            children.append(link)
        }
        
        return .nonTerminal(.ash, children: children)
    }
    
    func parseHeader() throws -> AST.Node {
        parsing.append(.header)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let header = popTerminal("header") else { throw error(.expectedTerminal("header")) }
        children.append(.terminal(header))
        
        guard popTerminal("{") != nil else { throw error(.expectedTerminal("{")) }
        
        guard let name = popTerminal("name") else { throw error(.expectedTerminal("name")) }
        children.append(.terminal(name))
        
        guard popTerminal(":") != nil else { throw error(.expectedTerminal(":")) }
        
        guard let identifier = popTerminal(kind: .identifier) else { throw error(.expectedTerminalOfKind(.identifier)) }
        children.append(.terminal(identifier))
        
        guard parseBreak() else { throw error(.expectedNonTerminal(.break)) }
        
        guard let name = popTerminal("product") else { throw error(.expectedTerminal("product")) }
        children.append(.terminal(name))
        
        guard popTerminal(":") != nil else { throw error(.expectedTerminal(":")) }
        
        if let lib = popTerminal("lib") {
            children.append(.terminal(lib))
        } else if let exec = popTerminal("exec") {
            children.append(.terminal(exec))
        } else {
            throw error(.expectedTerminal("lib/exec"))
        }
        
        guard popTerminal("}") != nil else { throw error(.expectedTerminal("}")) }
        
        return .nonTerminal(.header, children: children)
    }
    
    func parseCompile() throws -> AST.Node {
        parsing.append(.compile)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let compile = popTerminal("compile") else { throw error(.expectedTerminal("compile")) }
        children.append(.terminal(compile))
        
        guard popTerminal("{") != nil else { throw error(.expectedTerminal("{")) }
        
        let urls = parseUrls()
        children.append(urls)
        
        
        guard popTerminal("}") != nil else { throw error(.expectedTerminal("}")) }
        
        return .nonTerminal(.compile, children: children)
    }
    
    func parseUrls() -> AST.Node {
        parsing.append(.urls)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if let url = popTerminal(kind: .url) {
            children.append(.terminal(url))
            
            while parseBreak(), let url_ = popTerminal(kind: .url) {
                children.append(.terminal(url_))
            }
        }
        
        return .nonTerminal(.urls, children: children)
    }
    
    
    
    func parseLink() throws -> AST.Node {
        parsing.append(.link)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let link = popTerminal("link") else { throw error(.expectedTerminal("link")) }
        children.append(.terminal(link))
        
        guard popTerminal("{") != nil else { throw error(.expectedTerminal("{")) }
        
        let dLibs = parseDLibs()
        children.append(dLibs)
        
        
        guard popTerminal("}") != nil else { throw error(.expectedTerminal("}")) }
        
        return .nonTerminal(.link, children: children)
    }
    
    func parseDLibs() -> AST.Node {
        parsing.append(.dLibs)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if let dLib = try? parseDLib() {
            children.append(dLib)
            
            while parseBreak(), let dLib_ = try? parseDLib() {
                children.append(dLib_)
            }
        }
        
        return .nonTerminal(.dLibs, children: children)
    }
    
    func parseDLib() throws -> AST.Node {
        parsing.append(.dLib)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        
        
        guard popTerminal("[") != nil else { throw error(.expectedTerminal("{")) }
        
        guard let numberSign = popTerminal("#") else { throw error(.expectedTerminal("#")) }
        children.append(.terminal(numberSign))
        
        if let numericLiteral = popTerminal(kind: .numericLiteral) {
            children.append(.terminal(numericLiteral))
            
            guard popTerminal(";") != nil else { throw error(.expectedTerminal(";")) }
            
            guard let url = popTerminal(kind: .url) else { throw error(.expectedTerminalOfKind(.url)) }
            children.append(.terminal(url))
        } else if let keyword = popTerminal(kind: .keyword) {
            children.append(.terminal(keyword))
        } else {
            throw error(.expectedTerminalOfKind(.numericLiteral))
        }
        
        
        guard popTerminal("]") != nil else { throw error(.expectedTerminal("}")) }
        
        return .nonTerminal(.dLib, children: children)
    }
    
    func parseInclude() throws -> AST.Node {
        parsing.append(.include)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let include = popTerminal("include") else { throw error(.expectedTerminal("include")) }
        children.append(.terminal(include))
        
        guard popTerminal("{") != nil else { throw error(.expectedTerminal("{")) }
        
        let urls = parseUrls()
        children.append(urls)
        
        
        guard popTerminal("}") != nil else { throw error(.expectedTerminal("}")) }
        
        return .nonTerminal(.include, children: children)
    }
    
    
}
