import Testing
import CoreGraphics
@testable import SwiftQiskitApp

@Suite("Bloch3DProjection")
struct Bloch3DProjectionTests {

    @Test("poles project above/below center on the vertical through center when azimuth is 0")
    func polesProjectVertically() {
        let projection = Bloch3DProjection(azimuth: 0, elevation: 0.35)
        let center = CGPoint(x: 100, y: 100)
        let radius = 80.0

        let zeroPole = projection.project(0, 0, 1, center: center, radius: radius)
        let onePole = projection.project(0, 0, -1, center: center, radius: radius)

        #expect(abs(zeroPole.point.x - center.x) < 1e-9)
        #expect(abs(onePole.point.x - center.x) < 1e-9)
        #expect(zeroPole.point.y < center.y)
        #expect(onePole.point.y > center.y)
    }

    @Test("a near-hemisphere point projects farther from center than its far-hemisphere mirror")
    func nearPointsProjectFartherThanFarPoints() {
        let projection = Bloch3DProjection(azimuth: 0, elevation: 0)
        let center = CGPoint(x: 100, y: 100)
        let radius = 80.0

        let near = projection.project(0.6, 0.8, 0, center: center, radius: radius)
        let far = projection.project(-0.6, -0.8, 0, center: center, radius: radius)

        #expect(near.depth > 0)
        #expect(far.depth < 0)
        #expect(abs(near.point.x - center.x) > abs(far.point.x - center.x))
    }

    @Test("silhouetteScale is d/sqrt(d^2 - 1) and exceeds 1")
    func silhouetteScaleMatchesFormula() {
        let projection = Bloch3DProjection(azimuth: 0, elevation: 0, cameraDistance: 4)

        let expected = 4.0 / (16.0 - 1.0).squareRoot()

        #expect(abs(projection.silhouetteScale - expected) < 1e-12)
        #expect(projection.silhouetteScale > 1)
    }
}
