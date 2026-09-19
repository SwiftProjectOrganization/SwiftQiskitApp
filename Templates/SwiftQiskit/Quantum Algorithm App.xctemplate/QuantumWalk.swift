//
//  QuantumWalk.swift
//  ___PACKAGENAME___
//
//  A discrete-time quantum walk on a 16-site cycle: a coin qubit (q0) plus
//  a 4-bit position register (q1..q4). Ported from SwiftQiskit's
//  Playgrounds.playground page 22Walk — see that page and
//  PlaygroundDocs/22WALKHELP.md for the full derivation.
//
//  No SwiftUI here. This file is pure math over SwiftQiskitCore's Matrix
//  and StateVector, so it can be tested and reasoned about independent of
//  the view layer. To port a different SwiftQiskit playground algorithm,
//  replace this file with the corresponding page's math and update
//  AlgorithmModel's inputs/outputs to match.
//

import Foundation
import SwiftQiskitCore

struct QuantumWalk {

    let siteCount: Int
    private let stepOperator: Matrix

    init(siteCount: Int = 16) {
        self.siteCount = siteCount
        self.stepOperator = Self.buildStepOperator(siteCount: siteCount)
    }

    /// |0,x⟩ → |0,x+1 mod n⟩ (coin 0: step right), |1,x⟩ → |1,x−1 mod n⟩
    /// (coin 1: step left) — a permutation matrix, so unitary by construction.
    private static func buildShift(siteCount: Int) -> Matrix {
        let dimension = siteCount * 2
        var shift = Matrix(rows: dimension, cols: dimension)
        for coin in 0...1 {
            for pos in 0..<siteCount {
                let newPos = coin == 0 ? (pos + 1) % siteCount : (pos - 1 + siteCount) % siteCount
                let fromIndex = coin * siteCount + pos
                let toIndex = coin * siteCount + newPos
                shift[toIndex, fromIndex] = .one
            }
        }
        return shift
    }

    /// One step: a Hadamard coin flip, then the conditional shift.
    private static func buildStepOperator(siteCount: Int) -> Matrix {
        let hadamard = HadamardGate.matrix
        let identity = Matrix.identity(size: siteCount)
        return buildShift(siteCount: siteCount) * hadamard.tensor(identity)
    }

    private func initialState(coin: Ket) -> Ket {
        var posAmp = Array(repeating: Complex.zero, count: siteCount)
        posAmp[0] = .one
        return coin.tensor(StateVector(posAmp))
    }

    private func positionDistribution(_ psi: Ket) -> [Double] {
        var dist = Array(repeating: 0.0, count: siteCount)
        for coin in 0...1 {
            for pos in 0..<siteCount { dist[pos] += psi[coin * siteCount + pos].magnitudeSquared }
        }
        return dist
    }

    /// Position distribution after `steps` steps, starting from a chosen coin state.
    func quantumDistribution(coin: Ket, steps: Int) -> [Double] {
        var psi = initialState(coin: coin)
        for _ in 0..<steps { psi.apply(stepOperator) }
        return positionDistribution(psi)
    }

    /// The classical (diffusive) random walk over the same cycle, for comparison.
    func classicalDistribution(steps: Int) -> [Double] {
        var dist = Array(repeating: 0.0, count: siteCount)
        dist[0] = 1.0
        for _ in 0..<steps {
            var next = Array(repeating: 0.0, count: siteCount)
            for (pos, p) in dist.enumerated() {
                next[(pos + 1) % siteCount] += 0.5 * p
                next[(pos - 1 + siteCount) % siteCount] += 0.5 * p
            }
            dist = next
        }
        return dist
    }

    /// A cyclic-coordinate gotcha: computing variance from raw site *indices*
    /// is wrong once the distribution's support crosses the 0/n wraparound
    /// boundary — index n-1 is actually adjacent to index 0, but naive
    /// variance treats them as far apart. Unwrap each index to a signed
    /// offset from the start site before computing variance (valid as long
    /// as the spread stays under half the cycle).
    func signedOffset(_ pos: Int) -> Int { pos <= siteCount / 2 ? pos : pos - siteCount }

    func standardDeviation(of distribution: [Double]) -> Double {
        var mean = 0.0
        for (pos, p) in distribution.enumerated() { mean += Double(signedOffset(pos)) * p }
        var variance = 0.0
        for (pos, p) in distribution.enumerated() { variance += p * pow(Double(signedOffset(pos)) - mean, 2) }
        return variance.squareRoot()
    }

    /// S†S = I max diff — a check that the shift is a genuine permutation
    /// (unitary). Expected: ~0.0.
    func shiftUnitarityCheck() -> Double {
        let shift = Self.buildShift(siteCount: siteCount)
        let product = (shift†) * shift
        var maxAbs = 0.0
        for i in 0..<product.rows {
            for j in 0..<product.cols {
                let expected: Complex = (i == j) ? .one : .zero
                maxAbs = max(maxAbs, (product[i, j] - expected).magnitude)
            }
        }
        return maxAbs
    }
}
