import Foundation

struct PendulumEngine {
    static func landingIndex(segmentCount: Int, seed: UInt64? = nil) -> Int {
        guard segmentCount > 0 else { return 0 }
        if let seed {
            var generator = SeededGenerator(seed: seed)
            return Int.random(in: 0..<segmentCount, using: &generator)
        }
        return Int.random(in: 0..<segmentCount)
    }

    static func arcAngle(for index: Int, count: Int, span: Double = 140) -> Double {
        guard count > 1 else { return 0 }
        let start = -span / 2
        let step = span / Double(count - 1)
        return start + step * Double(index)
    }

    static func swingKeyframes(
        targetAngle: Double,
        oscillations: Int = 5,
        reduceMotion: Bool
    ) -> [Double] {
        if reduceMotion { return [targetAngle] }
        var frames: [Double] = [0]
        var amplitude = targetAngle * 1.4
        for i in 0..<oscillations {
            let direction: Double = i % 2 == 0 ? 1 : -1
            let overshoot = amplitude * direction
            frames.append(overshoot)
            amplitude *= 0.62
        }
        frames.append(targetAngle)
        return frames
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xDEADBEEF : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
