//
//  Lexer.swift
//  


import Foundation

/// Lexical analyzer
public class Lexer {
    
    /// Initialize a Lexer
    public init() {
        self.chars = []
        self.pos = 0
        self.line = 1
    }
    
    
    var chars: [Character]
    var pos: Int
    var line: Int
    var fileType: File.FileType!

    // Helpers
    
    
    /// Increment line counter.
    func newLine() {
        line += 1
    }
    
    
    /// Returns whether there is a character avaiable.
    func isAvaiable(_ off: Int = 0) -> Bool {
        return pos + off < chars.count
    }
    
    
    /// Returns the character if it is avaiable. Otherwise returns nil.
    func char(_ off: Int = 0) -> Character? {
        if isAvaiable(off) {
            return chars[pos + off]
        } else {
            return nil
        }
    }
    
    
    /// Returns nexe n characters if they are avaiable. Otherwise returns nil.
    func chars(_ n: Int) -> [Character]? {
        if isAvaiable(n - 1) {
            var chars = [Character]()
            for i in pos..<pos + n {
                chars.append(self.chars[i])
            }
            return chars
        } else {
            return nil
        }
    }
    
    
    /// Increment char counter by offset.
    func pop(_ off: Int = 1) {
        pos += off
    }
    
    /// Generate an array of tokens from a file
    /// - Parameter file: File to tokenize
    /// - Returns: Array of tokens
    /// - Throws: Throws LexerError
    public func tokenize(file: File) throws -> [Token]{
        
        
        self.fileType = file.fileType
        self.chars = .init(file.content)
        self.line = 1
        self.pos = 0
        
        switch fileType! {
        case .ash:
            return try tokenizeAsh()
        case .asm:
            return try tokenizeAsm()
            
        }
    }
    
    /// Tokenize ash file
    func tokenizeAsh() throws-> [Token] {
        var tokens = [Token]()
        while isAvaiable() {
            switch char() {
                
            // Comment
            case "/":
                handleComment()
            
            // Newline
            case "\n":
                if (tokens.last?.lexeme != "\n") {
                    tokens.append(.init(lexeme: "\n", kind: .punctuation, line: line))
                }
                newLine()
                pop()
                
            // Whitespace
            case " ", "\t":
                pop()
                
            // Punctuation
            case "{", "}", ":", ",", ";", "[", "]":
                tokens.append(handlePunctuation())
            
            
            
            // Numeric literal
            case "-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                try tokens.append(handleNumericLiteral())
            
            // Word
            case "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V","W" ,"X", "Y", "Z", "_":
                try tokens.append(handleWord())
                
            case "\"":
                try tokens.append(handleUrl())
            case "#", "=":
                tokens.append(handleOperator())
            default:
                throw LexerError.init(line: line, kind: .invalidCharacter)
            }
        }
        return tokens
    }
    
    
    /// Tokenize asm file
    func tokenizeAsm() throws -> [Token] {
        var tokens = [Token]()
        while isAvaiable() {
            switch char() {
                
            // Comment
            case "/":
                handleComment()
            
            // Newline
            case "\n":
                if (tokens.last?.lexeme != "\n") {
                    tokens.append(.init(lexeme: "\n", kind: .punctuation, line: line))
                }
                newLine()
                pop()
                
            // Whitespace
            case " ", "\t":
                pop()
                break
                
            // Punctuation
            case "{", "}", "[", "]", "(", ")", ":", ",", ";", ".":
                tokens.append(handlePunctuation())
            
            
            // Character literal
            case "\"":
                try tokens.append(handleCharLiteral())
            
            // Numeric literal
            case "-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                try tokens.append(handleNumericLiteral())
            
            // Word
            case "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V","W" ,"X", "Y", "Z", "_":
                try tokens.append(handleWord())
                
            case "#", "=":
                tokens.append(handleOperator())
            default:
                throw LexerError.init(line: line, kind: .invalidCharacter)
            }
        }
        tokens.append(.init(lexeme: "", kind: .eof, line: line))
        return tokens
    }
    
    /// Handle comment
    func handleComment() {
        while (char() != "\n" && pos < chars.count) {
            pop()
        }
    }
    
    
    ///  handle punctuation
    func handlePunctuation() -> Token {
        let token = Token(lexeme: String(char()!), kind: .punctuation, line: line)
        pop()
        return token
    }
    
    func handleCharLiteral() throws -> Token {
        pop()
        if let chars = chars(2), let ascii = chars[0].asciiValue, ascii > 31 && chars[1] == "\"" {
            pop(2)
            return Token(lexeme: String(chars[0]), kind: .charLiteral, line: line)
            
        } else if let chars = chars(3), chars[0] == "\\" && chars[1] == "n" && chars[2] == "\"" {
            pop(3)
            return Token(lexeme: "\n", kind: .charLiteral, line: line)
           
        }
        throw LexerError(line: line, kind: .invalidCharLiteral)
    }
    
    /// Handle numeric literal
    func handleNumericLiteral() throws -> Token {
        var radix: String = "0d"
        var sign: String = ""
        var number: String = ""
        if char()! == "-" {
            sign = "-"
            pop()
        }
        
        if let _radix = chars(2), _radix[0] == "0" {
            switch _radix[1] {
            case "d":
                radix = "Od"
                pop(2)
            case "x":
                radix = "0x"
                pop(2)
            case "o":
                radix = "0o"
                pop(2)
            case "b":
                radix = "0b"
                pop(2)
            default:
                break
            }
        }
        
        if let digit = char(), !Resources.validNumericLiteralDigits.contains(digit){
            throw LexerError(line: line, kind: .invalidNumericLiteral)
        }
        if !isAvaiable() {
            throw LexerError(line: line, kind: .invalidNumericLiteral)
        }
        
        while let digit = char(), Resources.validNumericLiteralDigits.contains(digit){
            number.append(digit)
            pop()
        }
        
        let content = sign + radix + number
        
        return Token(lexeme: content, kind: .numericLiteral, line: line)
        
    }
    
    /// Handle keyword, instruction, identifier
    func handleWord() throws -> Token {
        var content = String()
        while let char = char(), Resources.validLabelCharacters.contains(char) {
            content.append(char)
            pop()
        }
        
        if Resources.keywords(for: fileType).contains(content) {
            return Token(lexeme: content, kind: .keyword, line: line)
        } else if Resources.instructions().contains(content.lowercased()) {
            return Token(lexeme: content.lowercased(), kind: .instruction, line: line)
        }
        
        return Token(lexeme: content, kind: .identifier, line: line)
    }
    
    /// Handle operator
    func handleOperator() -> Token {
        let token = Token(lexeme: String(char()!), kind: .operator, line: line)
        pop()
        return token
    }
    
    /// Handle URL
    func handleUrl() throws -> Token {
        var string = ""
        
        pop()
        while let char = char(), char != "\"" {
           
            string.append(char)
            pop()
        }
        if let char = char(), char == "\"" {
            pop()
            return .init(lexeme: string, kind: .url, line: line)
        }
        
        throw LexerError(line: line, kind: .invalidUrl)
    }
    
}
