import SwiftUI

// MARK: - Enhanced Text Field
struct EnhancedTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    @FocusState private var isFocused: Bool
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? .blue : .secondary)
                .frame(width: 20)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            // Text Field
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(keyboardType)
                .autocapitalization(autocapitalization)
                .focused($isFocused)
                .onChange(of: isFocused) { focused in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isAnimating = focused
                    }
                    if focused {
                        // HapticManager.shared.lightImpact()
                    }
                }
            
            // Clear button
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    // HapticManager.shared.lightImpact()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}

// MARK: - Enhanced Secure Field
struct EnhancedSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    @FocusState private var isFocused: Bool
    @State private var isAnimating = false
    @State private var isPasswordVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? .blue : .secondary)
                .frame(width: 20)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            // Secure Field
            Group {
                if isPasswordVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textFieldStyle(PlainTextFieldStyle())
            .focused($isFocused)
            .onChange(of: isFocused) { focused in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAnimating = focused
                }
                if focused {
                    // HapticManager.shared.lightImpact()
                }
            }
            
            // Toggle password visibility
            Button(action: {
                isPasswordVisible.toggle()
                // HapticManager.shared.lightImpact()
            }) {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
            }
            .transition(.scale.combined(with: .opacity))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isPasswordVisible)
    }
}

// MARK: - Enhanced Button
struct EnhancedButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let style: ButtonStyle
    let isLoading: Bool
    
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary, secondary, destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return Color(.systemGray5)
            case .destructive: return .red
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .primary
            case .destructive: return .white
            }
        }
    }
    
    init(
        title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // HapticManager.shared.buttonPressed()
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(style.foregroundColor)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .fontWeight(.semibold)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [style.backgroundColor, style.backgroundColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: style.backgroundColor.opacity(0.3), radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
            )
            .foregroundColor(style.foregroundColor)
        }
        .disabled(isLoading)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Enhanced Toggle
struct EnhancedToggle: View {
    @Binding var isOn: Bool
    let title: String
    let subtitle: String?
    let icon: String?
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isOn ? .blue : .secondary)
                    .frame(width: 20)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .onChange(of: isOn) { _ in
                    HapticManager.shared.toggleChanged()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Enhanced Picker
struct EnhancedPicker<SelectionValue: Hashable, Content: View>: View {
    @Binding var selection: SelectionValue
    let title: String
    let icon: String?
    @ViewBuilder let content: () -> Content
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 20)
                }
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                    HapticManager.shared.lightImpact()
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            
            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Form Section
struct EnhancedFormSection<Content: View>: View {
    let title: String
    let icon: String?
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
} 