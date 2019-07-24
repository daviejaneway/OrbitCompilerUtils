//
//  SourceReader.swift
//  OrbitCompilerUtils
//
//  Created by Davie Janeway on 24/07/2019.
//

import Foundation

public class SourceReader : Phase {
    public typealias InputType = String
    public typealias OutputType = String
    
    public func execute(input: String) throws -> String {
        guard let source = FileManager.default.contents(atPath: input) else {
            throw OrbitError(message: "Could not find Orbit source file at \(input)")
        }
        
        guard let str = String(data: source, encoding: .utf8) else {
            throw OrbitError(message: "Could not open source file: \(input)")
        }
        
        return str
    }
}
