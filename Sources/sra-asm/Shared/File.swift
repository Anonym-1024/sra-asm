//
//  File.swift
//  


import Foundation

public typealias SourceCode = String


/// A structure representing a source code file
public struct File {
    
    /// Initialize a file at URL with a specified type
    public init(url: URL, fileType: File.FileType) {
        self.url = url
        self.fileType = fileType
    }
    
    public let url: URL
    public let fileType: FileType
    
    public var content: SourceCode {
        try! String(contentsOf: url)
    }
    
    /// File type
    public enum FileType: String {
        case asm = "asm"
        case ash = "ash"
    }
}
