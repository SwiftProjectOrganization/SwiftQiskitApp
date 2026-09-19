//
//  AlgorithmModel.swift
//  ___PACKAGENAME___
//
//  The view model: holds the algorithm's inputs, and recomputes its
//  outputs whenever an input changes. Recompute is explicit (`recompute()`
//  on `didSet`) rather than a computed property, because a real algorithm
//  port — e.g. a VQE optimizer sweep — may be too expensive to redo on
//  every view render. If you port an async/expensive algorithm, make
//  `recompute()` async and call it from a `Task` instead.
//

import SwiftUI
import SwiftQiskitCore

@MainActor
@Observable
final class AlgorithmModel {

    var steps: Int = 7 {
        didSet { recompute() }
    }

    var symmetricCoin: Bool = false {
        didSet { recompute() }
    }

    private(set) var quantumDistribution: [Double] = []
    private(set) var classicalDistribution: [Double] = []
    private(set) var quantumSigma: Double = 0
    private(set) var classicalSigma: Double = 0

    private let walk = QuantumWalk()

    init() {
        recompute()
    }

    private func recompute() {
        let coin: Ket = symmetricCoin ? .plusI : .zero
        quantumDistribution = walk.quantumDistribution(coin: coin, steps: steps)
        classicalDistribution = walk.classicalDistribution(steps: steps)
        quantumSigma = walk.standardDeviation(of: quantumDistribution)
        classicalSigma = walk.standardDeviation(of: classicalDistribution)
    }

    var siteCount: Int { walk.siteCount }

    func signedOffset(_ pos: Int) -> Int { walk.signedOffset(pos) }
}
