import SwiftUI

struct ListCard: View {
    let list: GroceryList
    
    var openCount: Int {
        list.items.filter { !$0.bought }.count
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Text(list.icon)
                .font(.system(size: 32))
                .frame(width: 58, height: 58)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            VStack(alignment: .leading, spacing: 5) {
                Text(list.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("\(list.items.count) items · \(openCount) open")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
