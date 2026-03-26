import SwiftUI
import MediaPipeTasksVision

struct OverlayView: View {
    var landmarks: [NormalizedLandmark]?
    var ballPath: [CGPoint]
    var racketPath: [CGPoint]
    
    // Define connections for the skeleton (simplified for tennis focus)
    let connections: [(Int, Int)] = [
        (11, 12), // Shoulders
        (11, 13), (13, 15), // Left Arm
        (12, 14), (14, 16), // Right Arm
        (11, 23), (12, 24), // Torso
        (23, 24), // Hips
        (23, 25), (25, 27), // Left Leg
        (24, 26), (26, 28)  // Right Leg
    ]

    // Triplets describe angle arcs (a - pivot - c)
    let angleTriplets: [(Int, Int, Int)] = [
        (11, 13, 15), // Left elbow
        (12, 14, 16), // Right elbow
        (13, 11, 23), // Left shoulder to torso
        (14, 12, 24), // Right shoulder to torso
        (23, 25, 27), // Left knee
        (24, 26, 28)  // Right knee
    ]
    
    var body: some View {
        GeometryReader { geometry in
            // Layer 1: Skeleton
            if let landmarks = landmarks {
                Path { path in
                    for (startIdx, endIdx) in connections {
                        guard startIdx < landmarks.count, endIdx < landmarks.count else { continue }
                        
                        let startPoint = point(for: landmarks[startIdx], in: geometry.size)
                        let endPoint = point(for: landmarks[endIdx], in: geometry.size)
                        
                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                    }
                }
                .stroke(Color.white.opacity(0.85), lineWidth: 2)

                Path { path in
                    for (aIdx, pivotIdx, cIdx) in angleTriplets {
                        guard aIdx < landmarks.count,
                              pivotIdx < landmarks.count,
                              cIdx < landmarks.count else { continue }

                        let a = point(for: landmarks[aIdx], in: geometry.size)
                        let pivot = point(for: landmarks[pivotIdx], in: geometry.size)
                        let c = point(for: landmarks[cIdx], in: geometry.size)
                        addAngleArc(path: &path, a: a, pivot: pivot, c: c)
                    }
                }
                .stroke(Color.white.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            
            // Layer 2: Ball Path (Fading Yellow)
            if !ballPath.isEmpty {
                Path { path in
                    path.addLines(ballPath)
                }
                .stroke(
                    LinearGradient(gradient: Gradient(colors: [.clear, .yellow]), startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
            }
            
            // Layer 3: Racket Path (Fading Neon Blue)
            if !racketPath.isEmpty {
                Path { path in
                    path.addLines(racketPath)
                }
                .stroke(
                    LinearGradient(gradient: Gradient(colors: [.clear, Color(red: 0.1, green: 1.0, blue: 1.0)]), startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
    
    private func point(for landmark: NormalizedLandmark, in size: CGSize) -> CGPoint {
        // MediaPipe coordinates are normalized [0, 1], y is down
        return CGPoint(x: CGFloat(landmark.x) * size.width, y: CGFloat(landmark.y) * size.height)
    }

    private func addAngleArc(path: inout Path, a: CGPoint, pivot: CGPoint, c: CGPoint) {
        let vecAP = CGVector(dx: a.x - pivot.x, dy: a.y - pivot.y)
        let vecCP = CGVector(dx: c.x - pivot.x, dy: c.y - pivot.y)
        let lenAP = hypot(vecAP.dx, vecAP.dy)
        let lenCP = hypot(vecCP.dx, vecCP.dy)

        guard lenAP > 5, lenCP > 5 else { return }

        let start = Angle(radians: atan2(vecAP.dy, vecAP.dx))
        let end = Angle(radians: atan2(vecCP.dy, vecCP.dx))
        var delta = end.radians - start.radians

        if delta <= -.pi { delta += 2 * .pi }
        if delta > .pi { delta -= 2 * .pi }

        let limitedDelta = max(min(delta, .pi * 0.75), -.pi * 0.75)
        let radius = min(max(min(lenAP, lenCP) * 0.4, 16), 36)

        path.addRelativeArc(center: pivot,
                             radius: radius,
                             startAngle: start,
                             delta: Angle(radians: limitedDelta))
    }
}
