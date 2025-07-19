import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearchButtonClicked: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    
    init(text: Binding<String>, placeholder: String = "Search...", onSearchButtonClicked: (() -> Void)? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.onSearchButtonClicked = onSearchButtonClicked
    }
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .onSubmit {
                        onSearchButtonClicked?()
                    }
                
                if !text.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            text = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isFocused {
                Button("Cancel") {
                    withAnimation {
                        text = ""
                        isFocused = false
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}