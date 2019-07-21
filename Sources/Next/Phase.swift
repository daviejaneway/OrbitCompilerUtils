//
//  Phase.swift
//  OrbitCompilerUtils
//
//  Created by Davie Janeway on 21/07/2019.
//

import Foundation

public protocol Phase {
    associatedtype InputType
    associatedtype OutputType
    
    func execute(input: InputType) -> OutputType
}

class Chain<I: Phase, O: Phase> : Phase where I.OutputType == O.InputType {
    typealias InputType = I.InputType
    typealias OutputType = O.OutputType
    
    private let inputPhase: I
    private let outputPhase: O
    
    init(inputPhase: I, outputPhase: O) {
        self.inputPhase = inputPhase
        self.outputPhase = outputPhase
    }
    
    func execute(input: I.InputType) -> O.OutputType {
        return self.outputPhase.execute(input: self.inputPhase.execute(input: input))
    }
}
