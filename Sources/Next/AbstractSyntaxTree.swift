//
//  AbstractSyntaxTree.swift
//  OrbitCompilerUtils
//
//  Created by Davie Janeway on 21/07/2019.
//

import Foundation

public class NodeData : Hashable {
    private let uuid = UUID()
    
    public func hash(into hasher: inout Hasher) {
        uuid.hash(into: &hasher)
    }
    
    public static func ==(lhs: NodeData, rhs: NodeData) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

public protocol Node : class {
    var identifier: UUID { get }
    var data: Set<NodeData> { get set }
    var children: [Node] { get set }
    
    func accept(visitor: NodeVisitor)
}

extension Node {
    func attach(data: NodeData) {
        self.data.insert(data)
    }
}

public protocol NodeVisitor {
    func visit(node: Node)
}
