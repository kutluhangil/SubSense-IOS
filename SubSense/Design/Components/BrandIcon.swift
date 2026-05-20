import SwiftUI

struct BrandIcon: View {
    let name: String
    var brandColor: Color = .brand
    var logoURL: URL? = nil
    var size: CGFloat = 44
    var radius: CGFloat = AppRadius.icon

    var body: some View {
        Group {
            if let url = logoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure, .empty:
                        fallbackView
                    @unknown default:
                        fallbackView
                    }
                }
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius))
    }

    private var fallbackView: some View {
        ZStack {
            brandColor.opacity(0.15)
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(brandColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(brandColor.opacity(0.2), lineWidth: 1)
        }
    }
}
