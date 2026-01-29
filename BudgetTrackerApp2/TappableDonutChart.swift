import SwiftUI

struct TappableDonutChart: View {
    let breakdown: [CategoryBreakdownItem]
    let onSelect: (CategoryBreakdownItem) -> Void

    var total: Double {
        breakdown.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                ForEach(breakdown.indices, id: \.self) { index in
                    let item = breakdown[index]
                    let startAngle = angle(at: index)
                    let endAngle = angle(at: index + 1)
                    let pos = labelPosition(startAngle: startAngle,
                                            endAngle: endAngle,
                                            center: center,
                                            radius: radius)
                    let isSmallSlice = item.percent < 3 // e.g. 1–2%

                    DonutSlice(
                        center: center,
                        radius: radius,
                        thickness: radius * 0.45,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        color: item.category.color
                    )
                    .onTapGesture {
                        onSelect(item)
                    }

                    // Only show label for non-tiny slices
                    if !isSmallSlice {
                        VStack(spacing: 2) {
                            Text(item.category.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("$\(Int(item.amount)) • \(String(format: "%.0f", item.percent))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(4)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .position(pos)
                    }

                    // Invisible tap zone (works for all slices, including tiny ones)
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                        .position(pos)
                        .onTapGesture {
                            onSelect(item)
                        }
                }

                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: radius * 1.1, height: radius * 1.1)
                    .position(center)
            }
        }
    }

    private func angle(at index: Int) -> Angle {
        let sum = breakdown.prefix(index).reduce(0) { $0 + $1.amount }
        return .degrees((sum / total) * 360)
    }

    private func labelPosition(startAngle: Angle, endAngle: Angle, center: CGPoint, radius: CGFloat) -> CGPoint {
        let midAngle = (startAngle.radians + endAngle.radians) / 2
        let sliceAngle = abs(endAngle.radians - startAngle.radians)

        // Base label radius
        var labelRadius = radius * 0.82

        // Pull inward for tiny slices
        if sliceAngle < .pi / 12 {
            labelRadius *= 0.75
        }

        var x = center.x + cos(midAngle) * labelRadius
        var y = center.y + sin(midAngle) * labelRadius

        // Clamp to chart bounds
        x = min(max(x, center.x - radius + 50), center.x + radius - 50)
        y = min(max(y, center.y - radius + 30), center.y + radius - 30)

        return CGPoint(x: x, y: y)
    }

}

struct DonutSlice: View {
    let center: CGPoint
    let radius: CGFloat
    let thickness: CGFloat
    let startAngle: Angle
    let endAngle: Angle
    let color: Color

    var body: some View {
        Path { path in
            let innerRadius = radius - thickness
            path.addArc(center: center,
                        radius: radius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false)
            path.addArc(center: center,
                        radius: innerRadius,
                        startAngle: endAngle,
                        endAngle: startAngle,
                        clockwise: true)
            path.closeSubpath()
        }
        .fill(color)
    }
}
