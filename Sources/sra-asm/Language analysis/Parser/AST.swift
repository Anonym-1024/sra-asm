//
//  File.swift
//  
//
//  Created by Václav Koukola on 11.05.2024.
//

import Foundation
import ArgumentParser

public struct AST {
    public let fileType: File.FileType
    public let root: Node
    
    public struct Node {
        var isTerminal: Bool
        var terminal: Token?
        var nonterminal: NonTerminal?
        var children: [Self]?
        
        enum NonTerminal {
            case asm, sections, section, exec, functions, function, funcArgs, funcArg, location, instructions, instruction, `break`, label, args, arg, immediate, data, dataBlocks, dataBlock, variables, variable
            case ash, header, compile, urls, url, link, dLib, dLibs, include
        }
        
        static func terminal(_ content: Token) -> Self {
            Node(isTerminal: true, terminal: content, nonterminal: nil, children: nil)
        }
        
        static func nonTerminal(_ kind: NonTerminal, children: [Node]) -> Self {
            Node(isTerminal: false, terminal: nil, nonterminal: kind, children: children)
        }
        
        public func stringRep(level: Int) -> String {
            var string = ""
            var l = level
            if isTerminal {
                for _ in 0..<l {
                    string.append("|   ")
                }
                string.append("\(terminal!)\n")
            } else {
                for _ in 0...l {
                    string.append("|   ")
                }
                string.append("Non-terminal: \(nonterminal!)\n")
                for child in children ?? [] {
                    string.append(child.stringRep(level: l+1))
                }
            }
            return string
        }
        
    }
    
    
}
