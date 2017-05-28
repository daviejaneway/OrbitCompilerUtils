import XCTest
@testable import OrbitCompilerUtils

class TestPhaseA : CompilationPhase {
    typealias InputType = String
    typealias OutputType = Int
    
    init() {
        
    }
    
    func execute(input: String) throws -> Int {
        return Int(input)!
    }
}

class TestPhaseB : CompilationPhase {
    typealias InputType = Int
    typealias OutputType = String
    
    init() {
        
    }
    
    func execute(input: Int) throws -> String {
        return "\(input)"
    }
}

class OrbitCompilerUtilsTests: XCTestCase {
    
    func testCompilationPhase() {
        let phase = TestPhaseA()
        
        let result = try! phase.execute(input: "123")
        XCTAssertEqual(123, result)
    }
    
    func testCompilationChain() {
        let phaseA = TestPhaseA()
        let phaseB = TestPhaseB()
        
        let chain = CompilationChain(inputPhase: phaseA, outputPhase: phaseB)
        let result = try! chain.execute(input: "123")
        
        XCTAssertEqual("123", result)
    }
    
    func testOrbitError() {
        let error = OrbitError(message: "Error!")
        
        XCTAssertEqual("Error!", error.message)
    }
}
