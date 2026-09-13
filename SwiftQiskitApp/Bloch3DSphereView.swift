//
//  Bloch3DSphereView.swift
//  SwiftQiskitApp
//
//  Ported from SwiftQiskit/Playgrounds.playground/Sources/Bloch3DView.swift,
//  which lives in a playground Sources/ folder and isn't importable here.
//
//  Bloch sphere rendered as a rotatable 3D wireframe with perspective
//  projection. Drag the canvas to orbit the camera around the sphere.
//

import SwiftUI

/// Camera model for `Bloch3DSphereView`: the camera sits `cameraDistance`
/// sphere-radii from the origin, orbiting by an azimuth angle about the
/// z-axis and an elevation angle above the equator. A world point is
/// rotated into camera coordinates (right, depth, up) and then
/// perspective-divided: scale = d / (d − depth), so nearer points draw
/// larger. Pulled out of the view as a pure, testable value.
struct Bloch3DProjection {
    var azimuth: Double
    var elevation: Double
    var cameraDistance: Double = 4.0

    /// Rotate a world point into camera coordinates and perspective-project
    /// it. `depth` is the camera-space coordinate toward the viewer —
    /// positive means the near half of the sphere.
    func project(
        _ x: Double, _ y: Double, _ z: Double,
        center: CGPoint, radius: Double
    ) -> (point: CGPoint, depth: Double) {
        let sinA = sin(azimuth), cosA = cos(azimuth)
        let sinE = sin(elevation), cosE = cos(elevation)

        // Azimuth about z, then elevation about the camera's right axis
        let right = -x * sinA + y * cosA
        let toward = x * cosA + y * sinA
        let depth = toward * cosE + z * sinE
        let up = -toward * sinE + z * cosE

        let scale = cameraDistance / (cameraDistance - depth)
        return (
            CGPoint(
                x: center.x + right * scale * radius,
                y: center.y - up * scale * radius
            ),
            depth
        )
    }

    /// The sphere's outline under perspective is slightly larger than the
    /// unit disc — scale by d/√(d² − 1).
    var silhouetteScale: Double {
        cameraDistance / sqrt(cameraDistance * cameraDistance - 1)
    }
}

/// Rotatable 3D counterpart to `BlochSphereView`'s fixed oblique
/// projection. Orbiting the camera makes azimuth (φ) directly readable —
/// the axis `BlochSphereView` foreshortens most.
struct Bloch3DSphereView: View {

    let label: String
    let bloch: BlochVector
    /// Side length of the square canvas, in points
    let size: CGFloat

    /// Camera orbit angles, in radians. Defaults give the classic
    /// oblique view: y → right, z → up, x → toward the lower-left.
    @State private var azimuth: Double = 0.4
    @State private var elevation: Double = 0.35
    /// Translation already applied during the current drag
    @State private var lastDrag: CGSize = .zero

    init(label: String, bloch: BlochVector, size: CGFloat = 300) {
        self.label = label
        self.bloch = bloch
        self.size = size
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.headline)

            Canvas { context, canvasSize in
                let projection = Bloch3DProjection(azimuth: azimuth, elevation: elevation)
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let radius = min(canvasSize.width, canvasSize.height) / 2 - 30

                drawWireframe(context, projection: projection, center: center, radius: radius, front: false)
                drawAxes(context, projection: projection, center: center, radius: radius)
                drawStateVector(context, projection: projection, center: center, radius: radius)
                drawWireframe(context, projection: projection, center: center, radius: radius, front: true)
            }
            .frame(width: size, height: size)
            .gesture(orbitGesture)

            Text("drag to rotate")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text(readout)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var readout: String {
        var text = String(
            format: "x %+.3f  y %+.3f  z %+.3f\nθ %.3f rad  φ %.3f rad",
            bloch.x, bloch.y, bloch.z, bloch.theta, bloch.phi
        )
        if abs(bloch.magnitude - 1) > 1e-3 {
            text += String(format: "\n|r| %.3f", bloch.magnitude)
        }
        return text
    }

    private var orbitGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let deltaWidth = value.translation.width - lastDrag.width
                let deltaHeight = value.translation.height - lastDrag.height
                lastDrag = value.translation

                // Dragging right moves the front of the sphere right;
                // dragging down tips the front of the sphere down.
                azimuth -= Double(deltaWidth) * 0.01
                elevation = min(.pi / 2, max(-.pi / 2, elevation + Double(deltaHeight) * 0.01))
            }
            .onEnded { _ in
                lastDrag = .zero
            }
    }

    /// Latitude and longitude circles, split into near and far halves so the
    /// far half can be drawn dimmer — a depth cue instead of hidden-line
    /// removal.
    private func drawWireframe(
        _ context: GraphicsContext, projection: Bloch3DProjection, center: CGPoint, radius: Double, front: Bool
    ) {
        var path = Path()
        let steps = 64

        // Latitude circles every 30°, poles excluded
        for latitude in stride(from: -60.0, through: 60.0, by: 30.0) {
            let z = sin(latitude * .pi / 180)
            let r = cos(latitude * .pi / 180)
            addCircle(
                to: &path, projection: projection,
                point: { t in (r * cos(t), r * sin(t), z) },
                steps: steps, center: center, radius: radius, front: front
            )
        }

        // Meridians every 30° (each is a full great circle through the poles)
        for longitude in stride(from: 0.0, to: 180.0, by: 30.0) {
            let cosL = cos(longitude * .pi / 180)
            let sinL = sin(longitude * .pi / 180)
            addCircle(
                to: &path, projection: projection,
                point: { t in (cos(t) * cosL, cos(t) * sinL, sin(t)) },
                steps: steps, center: center, radius: radius, front: front
            )
        }

        context.stroke(
            path,
            with: .color(.secondary.opacity(front ? 0.45 : 0.12)),
            lineWidth: 0.5
        )

        // Silhouette: the sphere's outline under perspective is slightly
        // larger than the unit disc.
        if front {
            let silhouette = radius * projection.silhouetteScale
            let outline = Path(
                ellipseIn: CGRect(
                    x: center.x - silhouette, y: center.y - silhouette,
                    width: silhouette * 2, height: silhouette * 2
                )
            )
            context.stroke(outline, with: .color(.primary.opacity(0.6)), lineWidth: 1)
        }
    }

    /// Append the segments of one sampled circle whose midpoint lies in the
    /// requested (near or far) half of the sphere.
    private func addCircle(
        to path: inout Path, projection: Bloch3DProjection,
        point: (Double) -> (x: Double, y: Double, z: Double),
        steps: Int, center: CGPoint, radius: Double, front: Bool
    ) {
        for i in 0..<steps {
            let t0 = Double(i) / Double(steps) * 2 * .pi
            let t1 = Double(i + 1) / Double(steps) * 2 * .pi
            let p0 = point(t0)
            let p1 = point(t1)

            let a = projection.project(p0.x, p0.y, p0.z, center: center, radius: radius)
            let b = projection.project(p1.x, p1.y, p1.z, center: center, radius: radius)

            let isFront = (a.depth + b.depth) / 2 >= 0
            if isFront == front {
                path.move(to: a.point)
                path.addLine(to: b.point)
            }
        }
    }

    private func drawAxes(_ context: GraphicsContext, projection: Bloch3DProjection, center: CGPoint, radius: Double) {
        let axes: [(x: Double, y: Double, z: Double, label: String)] = [
            (1, 0, 0, "x"),
            (0, 1, 0, "y"),
            (0, 0, 1, "|0⟩"),
            (0, 0, -1, "|1⟩")
        ]

        for axis in axes {
            let tip = projection.project(axis.x, axis.y, axis.z, center: center, radius: radius)
            let tail = projection.project(-axis.x, -axis.y, -axis.z, center: center, radius: radius)

            var line = Path()
            line.move(to: tail.point)
            line.addLine(to: tip.point)
            context.stroke(line, with: .color(.secondary.opacity(0.5)), lineWidth: 0.5)

            // Label just beyond the axis tip
            let labelPoint = projection.project(
                axis.x * 1.15, axis.y * 1.15, axis.z * 1.15,
                center: center, radius: radius
            )
            context.draw(
                Text(axis.label).font(.caption2).foregroundStyle(.secondary),
                at: labelPoint.point
            )
        }
    }

    private func drawStateVector(_ context: GraphicsContext, projection: Bloch3DProjection, center: CGPoint, radius: Double) {
        let tip = projection.project(bloch.x, bloch.y, bloch.z, center: center, radius: radius)
        let foot = projection.project(bloch.x, bloch.y, 0, center: center, radius: radius)

        // Dashed drop lines: tip → equator plane → origin, a depth cue for
        // reading the vector's z and its azimuth
        var drop = Path()
        drop.move(to: tip.point)
        drop.addLine(to: foot.point)
        drop.addLine(to: center)
        context.stroke(
            drop,
            with: .color(.red.opacity(0.4)),
            style: StrokeStyle(lineWidth: 1, dash: [3, 3])
        )

        var arrow = Path()
        arrow.move(to: center)
        arrow.addLine(to: tip.point)
        context.stroke(arrow, with: .color(.red), lineWidth: 2)

        // Tip dot scaled by the perspective factor — nearer looks bigger
        let dotRadius = 4 * projection.cameraDistance / (projection.cameraDistance - tip.depth)
        let dot = Path(
            ellipseIn: CGRect(
                x: tip.point.x - dotRadius, y: tip.point.y - dotRadius,
                width: dotRadius * 2, height: dotRadius * 2
            )
        )
        context.fill(dot, with: .color(.red))
    }
}

#Preview {
    Bloch3DSphereView(label: "q0", bloch: BlochVector(x: 1, y: 0, z: 0))
}
