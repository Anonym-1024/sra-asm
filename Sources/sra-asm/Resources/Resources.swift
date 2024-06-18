//
// Resources.swift
//


import Foundation





enum Resources {
    static var validLabelCharacters: Set<Character> = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V","W" ,"X", "Y", "Z", "_", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    static var validNumericLiteralDigits: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "a", "b", "c", "d", "e", "f"]
    
    
    
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
}










