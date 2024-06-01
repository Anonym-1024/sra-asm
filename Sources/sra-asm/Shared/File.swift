//
//  File.swift
//  
//
//
//

import Foundation

public typealias SourceCode = String

public struct File {
    public init(url: URL, fileType: File.FileType) {
        self.url = url
        self.fileType = fileType
    }
    
    public let url: URL
    public let fileType: FileType
    
    public var content: SourceCode {
        try! String(contentsOf: url)
    }
    
    public enum FileType: String {
        case asm = "asm"
        case ash = "ash"
    }
}
