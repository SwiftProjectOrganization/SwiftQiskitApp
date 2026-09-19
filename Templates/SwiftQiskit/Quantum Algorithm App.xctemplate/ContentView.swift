//
//  ContentView.swift
//  ___PACKAGENAME___
//

import SwiftUI

struct ContentView: View {
    @State private var model = AlgorithmModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Discrete-time quantum walk")
                    .font(.title2.bold())

                Text("""
                A coin qubit and a 16-site position register on a cycle. Each \
                step flips the coin with a Hadamard, then shifts the position \
                left or right depending on the coin's value. Compare the \
                quantum walk's two-peaked, ballistic spread (σ grows \
                roughly linearly in the step count) against the classical \
                random walk's single-humped, diffusive spread (σ grows with \
                the square root of the step count).
                """)
                .font(.callout)
                .foregroundStyle(.secondary)

                controls

                DistributionChartView(model: model)

                sigmaSummary
            }
            .padding()
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 560)
        #endif
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper("Steps: \(model.steps)", value: $model.steps, in: 1...7)
            Toggle("Symmetric coin (|+i⟩ instead of |0⟩)", isOn: $model.symmetricCoin)
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    private var sigmaSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("σ (spread from start site)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Quantum: \(model.quantumSigma, specifier: "%.3f")    Classical: \(model.classicalSigma, specifier: "%.3f")")
                .font(.system(.body, design: .monospaced))
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}

#Preview {
    ContentView()
}
