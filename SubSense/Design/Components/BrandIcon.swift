import SwiftUI

struct BrandIcon: View {
    let name: String
    var assetName: String? = nil
    var brandColor: Color = .brand
    var logoURL: URL? = nil
    var size: CGFloat = 44
    var radius: CGFloat = AppRadius.icon

    var body: some View {
        Group {
            if let asset = assetName, !asset.isEmpty, UIImage(named: asset) != nil {
                ZStack {
                    Color.white
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .padding(size * 0.15)
                }
            } else if let url = logoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    default:
                        fallbackView
                    }
                }
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .overlay {
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
        }
    }

    private var fallbackView: some View {
        ZStack {
            brandColor.opacity(0.15)
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(brandColor)
        }
    }
}
