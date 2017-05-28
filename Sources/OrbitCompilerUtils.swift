/**
    When compiled, Orbit files run through a series of phases,
    each of which takes the output of a previous phase as its own input.
    A phase is reponsible for transforming, in some way, its input into
    an output compatible with the next phase in compilation chain.
 */
protocol CompilationPhase {
    associatedtype InputType
    associatedtype OutputType
    
    func execute(input: InputType) throws -> OutputType
}

/**
    A wrapper around two related compilation phases, A & B.
    The output type of A must match the input type of B.
    Chains are, themselves, chainable.
 */
class CompilationChain<I: CompilationPhase, O: CompilationPhase> : CompilationPhase where I.OutputType == O.InputType {
    typealias InputType = I.InputType
    typealias OutputType = O.OutputType
    
    let inputPhase: I
    let outputPhase: O
    
    init(inputPhase: I, outputPhase: O) {
        self.inputPhase = inputPhase
        self.outputPhase = outputPhase
    }
    
    internal func execute(input: I.InputType) throws -> OutputType {
        return try self.outputPhase.execute(input: self.inputPhase.execute(input: input))
    }
}

/// Base type for all compilation errors
class OrbitError : Error {
    let message: String
    
    init(message: String) {
        self.message = message
    }
}
