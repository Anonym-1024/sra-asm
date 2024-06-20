//
//  MakeHeader.swift
//


import Foundation
import ArgumentParser



struct MakeHeader: ParsableCommand {
    static var configuration: CommandConfiguration = .init(commandName: "header")
    
    @Argument(help: "New header name") var name: String
    
    func run() throws {
        print(FileManager.default.currentDirectoryPath)
    }
}
