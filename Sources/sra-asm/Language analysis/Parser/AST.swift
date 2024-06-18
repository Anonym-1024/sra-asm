//
//  File.swift
//  
//
//  Created by Václav Koukola on 11.05.2024.
//

import Foundation
import ArgumentParser
// TODO: Remove public from Node, root and stringRep(level: Int)


/// Abstract syntax tree
public struct AST {
    
    /// Type of file the AST represents
    let fileType: File.FileType
    
    /// Root node
    public let root: Node
    
    /// String representation of an AST
    public var strRep: String {
        root.stringRep(level: 0)
    }
    
    
    /// AST Node
    public struct Node {
        var isTerminal: Bool
        var terminal: Token?
        var nonterminal: NonTerminal?
        var children: [Self]?
        
        enum NonTerminal {
            case asm, sections, section, exec, functions, function, funcArgs, funcArg, location, instructions, instruction, `break`, label, args, arg, immediate, data, dataBlocks, dataBlock, variables, variable
            case ash, header, compile, urls, url, link, dLib, dLibs, include
        }
        
        /// Initialize a node containing a terminal symbol
        static func terminal(_ content: Token) -> Self {
            Node(isTerminal: true, terminal: content, nonterminal: nil, children: nil)
        }
        
        /// Initialize a node containing a nonterminal symbol
        static func nonTerminal(_ kind: NonTerminal, children: [Node]) -> Self {
            Node(isTerminal: false, terminal: nil, nonterminal: kind, children: children)
        }
        
        
        /// String representation of a node
        func stringRep(level: Int) -> String {
            var string = ""
            if isTerminal {
                for _ in 0..<(level) {
                    string.append("|   ")
                }
                string.append("\(terminal!)\n")
            } else {
                for _ in 0..<(level) {
                    string.append("|   ")
                }
                string.append("Non-terminal: \(nonterminal!)\n")
                for child in children ?? [] {
                    string.append(child.stringRep(level: level+1))
                }
            }
            return string
        }
        
    }
    
    
}
