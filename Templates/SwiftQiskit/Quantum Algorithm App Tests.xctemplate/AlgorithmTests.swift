import Testing
@testable import ___PACKAGENAME___
import SwiftQiskitCore

@Suite("QuantumWalk")
struct AlgorithmTests {

    private func expectClose(_ a: Double, _ b: Double, tolerance: Double = 1e-9) {
        #expect(abs(a - b) < tolerance)
    }

    @Test("shift operator is unitary: S†S = I")
    func shiftIsUnitary() {
        let walk = QuantumWalk()
        expectClose(walk.shiftUnitarityCheck(), 0, tolerance: 1e-12)
    }

    @Test("distributions stay normalized at every step")
    func distributionsSumToOne() {
        let walk = QuantumWalk()
        for steps in 1...7 {
            let quantum = walk.quantumDistribution(coin: .zero, steps: steps)
            let classical = walk.classicalDistribution(steps: steps)
            expectClose(quantum.reduce(0, +), 1)
            expectClose(classical.reduce(0, +), 1)
        }
    }

    @Test("classical walk is diffusive: σ/√t == 1 at every step")
    func classicalSpreadIsDiffusive() {
        let walk = QuantumWalk()
        for steps in 1...7 {
            let sigma = walk.standardDeviation(of: walk.classicalDistribution(steps: steps))
            expectClose(sigma / Double(steps).squareRoot(), 1, tolerance: 1e-6)
        }
    }

    @Test("quantum walk spreads faster than the classical walk by t=7")
    func quantumSpreadIsBallistic() {
        let walk = QuantumWalk()
        let quantumSigma = walk.standardDeviation(of: walk.quantumDistribution(coin: .zero, steps: 7))
        let classicalSigma = walk.standardDeviation(of: walk.classicalDistribution(steps: 7))
        #expect(quantumSigma > classicalSigma)
    }

    @Test("|+i⟩ coin gives a distribution symmetric about the start site")
    func symmetricCoinIsSymmetric() {
        let walk = QuantumWalk()
        let symmetric = walk.quantumDistribution(coin: .plusI, steps: 7)
        for (site, mirror) in [(1, 15), (3, 13), (5, 11), (7, 9)] {
            expectClose(symmetric[site], symmetric[mirror], tolerance: 1e-6)
        }
    }

    @Test("|0⟩ coin gives a distribution biased away from symmetry")
    func zeroCoinIsAsymmetric() {
        let walk = QuantumWalk()
        let biased = walk.quantumDistribution(coin: .zero, steps: 7)
        #expect(abs(biased[3] - biased[13]) > 0.1)
    }
}
