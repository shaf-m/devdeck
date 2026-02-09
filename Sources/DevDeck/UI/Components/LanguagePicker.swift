import SwiftUI

struct LanguagePicker: View {
    @Binding var selection: String
    let languages: [(String, String)] // (Display Name, Code)
    
    var selectedLanguageName: String {
        languages.first(where: { $0.1 == selection })?.0 ?? selection
    }
    
    var body: some View {
        Menu {
            ForEach(languages, id: \.1) { lang in
                Button(action: {
                    selection = lang.1
                }) {
                    HStack {
                        if selection == lang.1 {
                            Image(systemName: "checkmark")
                        }
                        LanguageIconView(language: lang.1, size: CGSize(width: 16, height: 16))
                            .frame(width: 16, height: 16)
                            .foregroundColor(.primary)
                        Text(lang.0)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                LanguageIconView(language: selection, size: CGSize(width: 16, height: 16))
                    .frame(width: 16, height: 16)
                    .clipped()
                
                Text(selectedLanguageName)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(height: 32)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .frame(width: 180) // Fixed width for consistency
    }
}
