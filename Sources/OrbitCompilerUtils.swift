import Foundation

public struct OrbitWarning {
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

public struct OrbitModule {
    public let absolutePath: String
}

public class OrbitSession {
    private var warnings = [OrbitWarning]()
    private var modulePaths = [String]()
    
    public init(modulePaths: [String] = []) {
        self.modulePaths = modulePaths
    }
    
    func add(modulePath: String) {
        guard !self.modulePaths.contains(modulePath) else { return }
        
        self.modulePaths.append(modulePath)
    }
    
    private func find(named: String, atPath: String) -> OrbitModule? {
        var path = URL(fileURLWithPath: atPath)
        path = path.appendingPathComponent(named)
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path.absoluteString, isDirectory: &isDir) {
            // Found the api in the current directory
            if !isDir.boolValue {
                // TODO: The module might be elsewhere on the path
                return nil
            }
            
            return OrbitModule(absolutePath: path.absoluteString)
        }
        
        return nil
    }
    
    /// Search for a compiled api across ORB_PATH
    public func findApi(named: String) -> OrbitModule? {
        if let mod = find(named: named, atPath: FileManager.default.currentDirectoryPath) {
            return mod
        }
        
        // TODO: Should really check every path for duplicates.
        // User needs to decide what to do if multiple modules with same name
        // exist on path
        
        for path in self.modulePaths {
            if let mod = find(named: named, atPath: path) {
                return mod
            }
        }
        
        return nil
    }
    
    public func push(warning: OrbitWarning) {
        self.warnings.append(warning)
    }
    
    public func popAll() {
        self.warnings.reversed().forEach { wrn in
            print(wrn.message)
        }
    }
}

/**
    When compiled, Orbit files run through a series of phases,
    each of which takes the output of a previous phase as its own input.
    A phase is reponsible for transforming, in some way, its input into
    an output compatible with the next phase in the compilation chain.
 */
public protocol CompilationPhase {
    associatedtype InputType
    associatedtype OutputType
    
    var session: OrbitSession { get }
    
    init(session: OrbitSession)
    
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
    
    public let session: OrbitSession
    
    let inputPhase: I
    let outputPhase: O
    
    public required init(session: OrbitSession) {
        self.session = session
        self.inputPhase = I(session: session)
        self.outputPhase = O(session: session)
    }
    
    public init(inputPhase: I, outputPhase: O) {
        self.session = inputPhase.session
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
    
    public let session: OrbitSession
    
    public required init(session: OrbitSession) {
        self.session = session
    }
    
    public func execute(input: String) throws -> String {
        guard let source = FileManager.default.contents(atPath: input) else {
            throw OrbitError(message: "Could not find Orbit source file at \(input)")
        }
        
        guard let str = String(data: source, encoding: .utf8) else { throw OrbitError(message: "Could not open source file: \(input)") }
        
        return str
    }
}
