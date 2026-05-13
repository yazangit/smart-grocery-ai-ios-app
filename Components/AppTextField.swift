import SwiftUI

struct AppTextField: View {
    let title: String
    @Binding var text: String
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 22)
            
            TextField(title, text: $text)
        }
        .font(.system(size: 17))
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
