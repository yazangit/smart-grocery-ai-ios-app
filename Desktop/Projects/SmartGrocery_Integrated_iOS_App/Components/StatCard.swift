import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 52, height: 52)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
            }
            
            Spacer()
        }
        .padding(18)
        .background(Color(.systemGray6).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
