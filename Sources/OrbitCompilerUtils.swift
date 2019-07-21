import Foundation

public struct Orbit {
    
}

public struct OrbitWarning {
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

public struct OrbitModule {
    public let absolutePath: String
}

public protocol NameMangler {
    func mangleTypeIdentifier(name: String) -> String
}

public protocol CallingConvention {
    var mangler: NameMangler { get }
    
    init()
}

public class OrbitNameMangler : NameMangler {
    public func mangleTypeIdentifier(name: String) -> String {
        return name
    }
}

public class OrbitCallingConvention : CallingConvention {
    public let mangler: NameMangler = OrbitNameMangler()
    
    public required init() {}
}

public protocol Annotation {
    var identifier: String { get }
    
    func equal(toOther annotation: Annotation) -> Bool
}

public protocol PhaseAnnotatonProtocol : Annotation {
    var targetPhaseIdentifier: String { get }
}

public enum OrbitFormat {
    case Source
    case API
}

public struct OrbitPath {
    public let url: URL
    public let format: OrbitFormat
}

public class OrbitSession {
    private var warnings = [OrbitWarning]()
    
    private let sourceFiles: [URL]
    private let orbPaths: [URL]
    
    public let callingConvention: CallingConvention
    
    public init(orbPaths: [URL] = [], sourceFiles: [URL] = [], callingConvention: CallingConvention = OrbitCallingConvention()) {
        self.sourceFiles = sourceFiles
        self.callingConvention = callingConvention
        self.orbPaths = orbPaths
    }
    
    public func findOrbitFile(named: String) throws -> OrbitPath {
        for path in self.orbPaths {
            if let result = try self.find(named: "\(named).api", atPath: path) {
                return OrbitPath(url: result, format: .API)
            } else if let result = try self.find(named: "\(named).orb", atPath: path) {
                return OrbitPath(url: result, format: .Source)
            }
        }
        
        throw OrbitError(message: "API '\(named)' not found in any path. Try adding -a <path_to_parent_directory>")
    }
    
    private func find(named: String, atPath: URL) throws -> URL? {
        let path = atPath.appendingPathComponent(named)
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path.path, isDirectory: &isDir) {
            guard !isDir.boolValue else { throw OrbitError(message: "Path '\(path.path)' is a directory, expected .api file") }
            
            return path
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
    
    var identifier: String { get }
    var session: OrbitSession { get }
    
    init(session: OrbitSession, identifier: String)
    
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
    
    public let identifier: String
    public let session: OrbitSession
    
    let inputPhase: I
    let outputPhase: O
    
    public required init(session: OrbitSession, identifier: String) {
        self.session = session
        self.identifier = identifier
        self.inputPhase = I(session: session, identifier: identifier)
        self.outputPhase = O(session: session, identifier: identifier)
    }
    
    public init(inputPhase: I, outputPhase: O) {
        self.session = inputPhase.session
        self.inputPhase = inputPhase
        self.outputPhase = outputPhase
        self.identifier = "\(inputPhase.identifier)->\(outputPhase.identifier)"
    }
    
    public func execute(input: I.InputType) throws -> OutputType {
        return try self.outputPhase.execute(input: self.inputPhase.execute(input: input))
    }
}

public enum TextColor : String {
    case Red = "33"
    case Green = "92"
}

public enum TextStyle : String {
    case Regular = "0"
    case Bold = "1"
}

/// Base type for all compilation errors
public class OrbitError : Error {
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
    
    public static func format(string: String, color: TextColor, style: TextStyle) -> String {
        // \u{001B}[1;92mSUCCESS\u{001B}[1;0m
        return "\u{001B}[\(style.rawValue);\(color.rawValue)m\(string)\u{001B}[0;0m"
    }
}

/*
    Compilation errors fall into one of three categories:
        1. A fatal error, usually a compiler bug. Compiler dev facing
        2. An error arising from bad source code. Could come from any compilation phase. User facing
        3. As 2, but error has known solutions. Compiler should present the problem and a list of possible solutions
 
    All errors should report the following information:
        a. The current compilation phase
        b. File/line/character information
 */
public class OrbitFatal : OrbitError {
    public override init(message: String) {
        super.init(message: "\(OrbitError.format(string: "FATAL", color: .Red, style: .Bold)) \(message)")
    }
}

public class OrbitProblem : OrbitError {
    init(problem: String, solutions: [String]) {
        let prob = OrbitError.format(string: "PROBLEM", color: .Red, style: .Bold)
        let sltn = OrbitError.format(string: "SOLUTIONS", color: .Red, style: .Bold)
        super.init(message: "\(prob)\n\t\(problem)\n\(sltn)\n\t\(solutions.enumerated().map { "\($0.offset). \($0.element)" }.joined(separator: "\n\t"))")
    }
}

public class SourceResolver : CompilationPhase {
    public typealias InputType = String
    public typealias OutputType = String
    
    public let identifier = "Orb.Compiler.Frontend.SourceResolver"
    public let session: OrbitSession
    
    public required init(session: OrbitSession, identifier: String = "") {
        self.session = session
    }
    
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
