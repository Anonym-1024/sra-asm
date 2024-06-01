//
//  File.swift
//  
//
//  Created by Václav Koukola on 11.05.2024.
//

import Foundation
import ArgumentParser

public struct AST {
    let fileType: File.FileType
    let root: Node
    
    struct Node {
        var isTerminal: Bool
        var terminal: Token?
        var nonterminal: NonTerminal?
        var children: [Self]?
        
        enum NonTerminal {
            case asm, sections, section, exec, execBlocks, execBlock, funcArgument, funcArguments, instructions, instruction, label, arguments, argument, imediate, data, dataBlocks, dataBlock, variables, variable
        }
        
        static func terminal(_ content: Token) -> Self {
            Node(isTerminal: true, terminal: content, nonterminal: nil, children: nil)
        }
        
        static func nonTerminal(_ kind: NonTerminal, children: [Node]) -> Self {
            Node(isTerminal: false, terminal: nil, nonterminal: kind, children: children)
        }
    }
    
    
}
