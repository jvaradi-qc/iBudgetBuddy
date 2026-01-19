import SwiftUI

struct ScreenshotTemplate<Content: View>: View {
    let caption: String
    let content: Content

    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    init(caption: String, @ViewBuilder content: () -> Content) {
        self.caption = caption
        self.content = content()
    }

    // MARK: - Device-Adaptive Sizes
    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var deviceContentSize: CGSize {
        if isPad {
            // Logical size of iPad Pro 13-inch (M4)
            return CGSize(width: 1024, height: 1366)
        } else {
            // Logical size of iPhone 15 Pro Max
            return CGSize(width: 390, height: 844)
        }
    }

    private var canvasSize: CGSize {
        if isPad {
            // Physical export size for iPad Pro 13-inch
            return CGSize(width: 2064, height: 2752)
        } else {
            // Physical export size for iPhone 15 Pro Max
            return CGSize(width: 1284, height: 2778)
        }
    }

    private var captionFontSize: CGFloat {
        isPad ? 40 : 24
    }

    private var topPadding: CGFloat {
        isPad ? 120 : 80
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            ScreenshotBackground()

            VStack(spacing: isPad ? 60 : 40) {
                Text(caption)
                    .font(.system(size: captionFontSize, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, isPad ? 80 : 40)

                content
                    .frame(width: deviceContentSize.width,
                           height: deviceContentSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: isPad ? 60 : 40))
                    .shadow(radius: isPad ? 30 : 20)
            }
            .padding(.top, topPadding)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }
}

