//
//  FakeRandom.swift
//  NavMeshDemo
//
//  Created by Miguel de Icaza on 9/15/23.
//

import Foundation

// We use this fake random generator, to ensure reproducible test runs
struct FakeRandom: RandomNumberGenerator {
    var state: UInt64 = 0
    
    mutating func next() -> UInt64 {
        state = state &+ 0xdeadbeef
        return state
    }
}

var fakeRandomSource = FakeRandom ()
func fakeRandom () -> Float {
    Float.random(in: 0..<1, using: &fakeRandomSource)
}

