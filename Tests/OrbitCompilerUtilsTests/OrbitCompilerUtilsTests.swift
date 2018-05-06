import XCTest
@testable import OrbitCompilerUtils

class TestPhaseA : CompilationPhase {
    var identifier: String
    
    required init(session: OrbitSession, identifier: String) {
        self.session = session
        self.identifier = identifier
    }
    
    typealias InputType = String
    typealias OutputType = Int
    
    let session: OrbitSession
    
    required init(session: OrbitSession) {
        self.session = session
        self.identifier = ""
    }
    
    func execute(input: String) throws -> Int {
        return Int(input)!
    }
}

class TestPhaseB : CompilationPhase {
    var identifier: String
    
    required init(session: OrbitSession, identifier: String) {
        self.session = session
        self.identifier = identifier
    }
    
    typealias InputType = Int
    typealias OutputType = String
    
    let session: OrbitSession
    
    required init(session: OrbitSession) {
        self.session = session
        self.identifier = ""
    }
    
    func execute(input: Int) throws -> String {
        return "\(input)"
    }
}

class OrbitCompilerUtilsTests: XCTestCase {
    static let session = OrbitSession()
    
    func testCompilationPhase() {
        let phase = TestPhaseA(session: OrbitCompilerUtilsTests.session)
        
        let result = try! phase.execute(input: "123")
        XCTAssertEqual(123, result)
    }
    
    func testCompilationChain() {
        let phaseA = TestPhaseA(session: OrbitCompilerUtilsTests.session)
        let phaseB = TestPhaseB(session: OrbitCompilerUtilsTests.session)
        
        let chain = CompilationChain(inputPhase: phaseA, outputPhase: phaseB)
        let result = try! chain.execute(input: "123")
        
        XCTAssertEqual("123", result)
    }
    
    func testOrbitError() {
        let error = OrbitError(message: "Error!")
        
        XCTAssertEqual("Error!", error.message)
    }
}
