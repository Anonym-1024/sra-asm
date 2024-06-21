//
// Resources.swift
//


import Foundation





enum Resources {
    static var validLabelCharacters: Set<Character> = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V","W" ,"X", "Y", "Z", "_", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    static var validNumericLiteralDigits: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "a", "b", "c", "d", "e", "f"]
    
    static var validRegisterNames: Set<String> = ["r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7"]
    
    static var validSystemRegisterNames: Set<String> = ["psr", "pc", "sp", "pdbr", "spsr", "spc", "ssp", "spdbr"]
    
    static var validPortNames: Set<String> = ["p0", "p1", "p2", "p3", "p4", "p5", "p6", "p7"]
    
    static var validNumberRange = (pow(2, 23) * -1)...(pow(2, 24) - 1)
    
    static func keywords(for fileType: File.FileType) -> Set<String> {
        let keywordsURL = Bundle.module.url(forResource: "Keywords_" + fileType.rawValue, withExtension: "txt")!
        let keywordsString = try! String(contentsOf: keywordsURL)
        return Set(keywordsString.components(separatedBy: "\n").dropLast())
    }
    
    static func instructions() -> Set<String> {
        let instructionsURL = Bundle.module.url(forResource: "Instructions", withExtension: "txt")!
        let instructionsString = try! String(contentsOf: instructionsURL)
        return Set(instructionsString.components(separatedBy: "\n").dropLast())
    }
    
    static func instructionFormat() -> [String: [SemanticAnalyzer.InstructionArgumentKind]] {
        var dict = [String: [SemanticAnalyzer.InstructionArgumentKind]]()
        
        let instructionFormatURL = Bundle.module.url(forResource: "Instruction_format", withExtension: "csv")!
        let instructionFormatString = try! String(contentsOf: instructionFormatURL)
        
        let components = instructionFormatString.components(separatedBy: "\n").dropLast()
        
        for component in components {
            let words = component.components(separatedBy: ",")
            
            var args = [SemanticAnalyzer.InstructionArgumentKind]()
            
            for i in 1...3 {
                if words[i] != "_" {
                    args.append(.init(rawValue: words[i])!)
                }
            }
            
            dict[words[0]] = args
        }
        
        return dict
    }
}










