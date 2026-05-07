import SwiftUI

struct CategoryIcon: View {
    let icon: String
    let colorHex: String
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: colorHex).opacity(0.15))
                .frame(width: size, height: size)
            Image(systemName: icon)
                .font(.system(size: size * 0.45))
                .foregroundColor(Color(hex: colorHex))
        }
    }
}
