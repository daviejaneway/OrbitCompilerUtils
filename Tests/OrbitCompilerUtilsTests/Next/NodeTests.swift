//
//  NodeTests.swift
//  OrbitCompilerUtilsTests
//
//  Created by Davie Janeway on 21/07/2019.
//

import XCTest
@testable import OrbitCompilerUtils

infix operator ~>
fileprivate func ~>(lhs: @escaping (Int, Int) -> Int, rhs: (Node, Node)) -> Node {
    let branch = OpNode(op: lhs, children: [rhs.0, rhs.1])
    
    return branch
}

private class IntNode : Node {
    let identifier = UUID()
    var data = Set<NodeData>()
    
    var children = [Node]()
    let value: Int
    
    init(value: Int) {
        self.value = value
    }
    
    func accept(visitor: NodeVisitor) {
        guard let mv = visitor as? MathVisitor else { fatalError() }
        
        mv.value = self.value
    }
}

private class OpNode : Node {
    let identifier = UUID()
    var data = Set<NodeData>()
    var children: [Node]
    let op: (Int, Int) -> Int
    
    init(op: @escaping (Int, Int) -> Int, children: [Node]) {
        self.op = op
        self.children = children
    }
    
    func accept(visitor: NodeVisitor) {
        guard let mv = visitor as? MathVisitor else { fatalError() }
        
        let lVisitor = MathVisitor()
        let rVisitor = MathVisitor()
        
        lVisitor.visit(node: self.children[0])
        rVisitor.visit(node: self.children[1])
        
        mv.value = self.op(lVisitor.value, rVisitor.value)
    }
}

private class MathVisitor : NodeVisitor {
    var value: Int = 0
    
    func visit(node: Node) {
        node.accept(visitor: self)
    }
}

class NodeTests: XCTestCase {
    func testTreeWalker() {
        let add: (Int, Int) -> Int = { $0 + $1 }
        let mul: (Int, Int) -> Int = { $0 * $1 }
        
        let root = mul ~> (IntNode(value: 2), add ~> (IntNode(value: 3), IntNode(value: 5)))
        
        let visitor = MathVisitor()
        
        visitor.visit(node: root)
        
        XCTAssertEqual(16, visitor.value)
    }
}
