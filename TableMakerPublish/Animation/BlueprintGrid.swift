//
//  BlueprintGrid.swift
//  TableMakerPublish
//
//  Lightweight grid for blueprint vibe. Uses Canvas for performance.
//

import SwiftUI

public struct BlueprintGrid: View {
    public var spacing: CGFloat
    public var lineWidth: CGFloat
    public var opacity: CGFloat
    public var animatedScale: CGFloat

    public init(spacing: CGFloat = 24, lineWidth: CGFloat = 0.5, opacity: CGFloat = 0.04, animatedScale: CGFloat = 1.0) {
        self.spacing = spacing
        self.lineWidth = lineWidth
        self.opacity = opacity
        self.animatedScale = animatedScale
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Canvas { context, _ in
                let color = BrandColors.seatInk.opacity(opacity)
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height)); x += spacing }
                var y: CGFloat = 0
                while y <= size.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y)); y += spacing }
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }
            .scaleEffect(animatedScale)
            .drawingGroup(opaque: false, colorMode: .linear)
        }
        .allowsHitTesting(false)
    }
}

public enum BrandColors {
    public static let seatBlue: Color = {
        Color(UIColor(named: "seatBlue") ?? UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(red: 0.47, green: 0.70, blue: 0.98, alpha: 1.0)
            } else {
                return UIColor(red: 0.12, green: 0.40, blue: 0.92, alpha: 1.0)
            }
        })
    }()

    public static let seatAccent: Color = {
        Color(UIColor(named: "seatAccent") ?? UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(red: 0.30, green: 0.85, blue: 0.95, alpha: 1.0)
            } else {
                return UIColor(red: 0.00, green: 0.68, blue: 0.90, alpha: 1.0)
            }
        })
    }()

    public static let seatInk: Color = {
        Color(UIColor(named: "seatInk") ?? UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(white: 0.88, alpha: 1.0)
            } else {
                return UIColor(white: 0.12, alpha: 1.0)
            }
        })
    }()

    public static let seatSurface: Color = {
        Color(UIColor(named: "seatSurface") ?? UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(red: 0.05, green: 0.07, blue: 0.10, alpha: 1.0)
            } else {
                return UIColor(red: 0.96, green: 0.98, blue: 1.00, alpha: 1.0)
            }
        })
    }()
}


