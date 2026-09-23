import SwiftUI

/// Hiệu ứng rung nhẹ cửa sổ khi hết giờ.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 4
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

extension View {
    func shake(trigger: Int) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
}

private struct ShakeModifier: ViewModifier {
    let trigger: Int
    @State private var shakes: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: shakes))
            .onChange(of: trigger) { _ in
                shakes = 0
                withAnimation(.linear(duration: 0.45)) {
                    shakes = 1
                }
            }
    }
}

/// Nhấp nháy nền khi hết giờ.
struct BlinkBackground: ViewModifier {
    let active: Bool
    let alertColor: Color
    let baseColor: Color
    @State private var on = false

    func body(content: Content) -> some View {
        content
            .background(
                (active && on ? alertColor.opacity(0.85) : baseColor)
                    .animation(.easeInOut(duration: 0.4), value: on)
            )
            .onChange(of: active) { isActive in
                if isActive {
                    on = true
                    // Toggle liên tục khi đang finished
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                        if !active {
                            timer.invalidate()
                            on = false
                            return
                        }
                        on.toggle()
                    }
                } else {
                    on = false
                }
            }
    }
}
