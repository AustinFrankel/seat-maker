import SwiftUI

struct TableCanvasView: View {
    let arrangement: SeatingArrangement
    let canvasSize: CGSize

    var body: some View {
        CanvasView(arrangement: arrangement, size: canvasSize)
            .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private struct CanvasView: View {
        let arrangement: SeatingArrangement
        let size: CGSize
        private let iconSize: CGFloat = 64
        private let calculator = SeatPositionCalculator()

        var body: some View {
            ZStack {
                Color.white
                tableShape
                    .stroke(Color(.sRGB, red: 0.13, green: 0.13, blue: 0.13, opacity: 1), lineWidth: 6)
                    .background(tableShape.fill(Color.white))
                ForEach(seatPositions().indices, id: \.self) { idx in
                    let pos = seatPositions()[idx]
                    Circle()
                        .fill(Color(white: 0.93))
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .frame(width: iconSize, height: iconSize)
                        .position(x: pos.x, y: pos.y)
                }
                Text(arrangement.title)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(.black)
                    .position(x: size.width/2, y: size.height/2)
            }
        }

        private var tableShape: some Shape {
            switch arrangement.tableShape {
            case .round:
                return AnyShape { _ in
                    Circle().path(in: CGRect(x: size.width/2 - 300, y: size.height/2 - 300, width: 600, height: 600))
                }
            case .rectangle:
                return AnyShape { _ in
                    RoundedRectangle(cornerRadius: 28).path(in: CGRect(x: size.width/2 - 360, y: size.height/2 - 240, width: 720, height: 480))
                }
            case .square:
                return AnyShape { _ in
                    RoundedRectangle(cornerRadius: 28).path(in: CGRect(x: size.width/2 - 320, y: size.height/2 - 320, width: 640, height: 640))
                }
            }
        }

        private func seatPositions() -> [CGPoint] {
            calculator.calculatePositions(for: arrangement.tableShape, in: size, totalSeats: arrangement.people.count, iconSize: iconSize)
        }
    }
}

private struct AnyShape: Shape, Sendable {
    private let builder: @Sendable (CGRect) -> Path
    init(_ path: @escaping @Sendable (CGRect) -> Path) { self.builder = path }
    func path(in rect: CGRect) -> Path { builder(rect) }
}

extension View {
    func renderAsUIImage(size: CGSize, scale: CGFloat = 2.0) -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        view?.bounds = CGRect(origin: .zero, size: size)
        view?.backgroundColor = .clear
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            view?.drawHierarchy(in: view?.bounds ?? .zero, afterScreenUpdates: true)
        }
    }
}


