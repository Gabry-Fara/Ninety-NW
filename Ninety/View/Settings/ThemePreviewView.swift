import SwiftUI

struct ThemePreviewView: View {
    let theme: AppTheme
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Mini UI Preview
            VStack(spacing: 4) {
                // Status bar mockup
                HStack {
                    Circle().frame(width: 4, height: 4)
                    Spacer()
                    RoundedRectangle(cornerRadius: 1).frame(width: 12, height: 4)
                }
                .padding(.horizontal, 6)
                .padding(.top, 4)
                .opacity(0.5)
                
                // Typical UI components mockup
                VStack(spacing: 6) {
                    // Title placeholder
                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: 30, height: 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // List items placeholders
                    ForEach(0..<3) { _ in
                        HStack(spacing: 4) {
                            Circle().frame(width: 10, height: 10)
                            RoundedRectangle(cornerRadius: 1.5).frame(height: 3)
                        }
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                        }
                    }
                }
                .padding(6)
                
                Spacer(minLength: 0)
            }
            .frame(width: 80, height: 120)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme == .light ? Color.white : Color(white: 0.15))
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            }
            
            // Theme Label
            VStack(spacing: 4) {
                Text(theme == .light ? "Light" : "Dark")
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .blue : .secondary.opacity(0.5))
            }
        }
        .padding(8)
        .contentShape(Rectangle())
    }
}

#Preview {
    HStack(spacing: 20) {
        ThemePreviewView(theme: .light, isSelected: true)
        ThemePreviewView(theme: .night, isSelected: false)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
