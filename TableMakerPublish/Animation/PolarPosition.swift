//
//  PolarPosition.swift
//  TableMakerPublish
//
//  Utility for positioning items on a circle using polar coordinates.
//

import SwiftUI

public struct PolarPosition {
    public static func point(onCircleWith center: CGPoint, radius: CGFloat, angleRadians: CGFloat) -> CGPoint {
        let x = center.x + radius * cos(angleRadians)
        let y = center.y + radius * sin(angleRadians)
        return CGPoint(x: x, y: y)
    }

    public static func pointsEvenlySpaced(count: Int, center: CGPoint, radius: CGFloat, startAngleRadians: CGFloat = -.pi / 2.0) -> [CGPoint] {
        guard count > 0 else { return [] }
        let step = (2.0 * .pi) / CGFloat(count)
        return (0..<count).map { index in
            let angle = startAngleRadians + CGFloat(index) * step
            return point(onCircleWith: center, radius: radius, angleRadians: angle)
        }
    }
}


