import Foundation

/**
    When compiled, Orbit files run through a series of phases,
    each of which takes the output of a previous phase as its own input.
    A phase is reponsible for transforming, in some way, its input into
    an output compatible with the next phase in compilation chain.
 */
public protocol CompilationPhase {
    associatedtype InputType
    associatedtype OutputType
    
    func execute(input: InputType) throws -> OutputType
}

/**
    A wrapper around two related compilation phases, A & B.
    The output type of A must match the input type of B.
    Chains are, themselves, chainable.
 */
public class CompilationChain<I: CompilationPhase, O: CompilationPhase> : CompilationPhase where I.OutputType == O.InputType {
    public typealias InputType = I.InputType
    public typealias OutputType = O.OutputType
    
    let inputPhase: I
    let outputPhase: O
    
    public init(inputPhase: I, outputPhase: O) {
        self.inputPhase = inputPhase
        self.outputPhase = outputPhase
    }
    
    public func execute(input: I.InputType) throws -> OutputType {
        return try self.outputPhase.execute(input: self.inputPhase.execute(input: input))
    }
}

/// Base type for all compilation errors
public class OrbitError : Error {
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

public class SourceResolver : CompilationPhase {
    public typealias InputType = String
    public typealias OutputType = String
    
    public func execute(input: String) throws -> String {
        guard let source = FileManager.default.contents(atPath: input) else {
            throw OrbitError(message: "Could not find Orbit source file at \(input)")
        }
        
        guard let str = String(data: source, encoding: .utf8) else { throw OrbitError(message: "Could not open source file: \(input)") }
        
        return str
    }
}
