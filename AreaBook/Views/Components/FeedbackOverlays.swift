import SwiftUI

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
        }
    }
}

// MARK: - Success Toast
struct SuccessToast: View {
    let message: String
    let icon: String
    @Binding var isShowing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.green)
        .cornerRadius(10)
        .shadow(radius: 5)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let message: String
    @Binding var isShowing: Bool
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer()
                
                Button {
                    withAnimation {
                        isShowing = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
            
            if let onRetry = onRetry {
                Button("Try Again") {
                    onRetry()
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.red)
        .cornerRadius(10)
        .shadow(radius: 5)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Confirmation Dialog
struct DeleteConfirmationDialog: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let destructiveAction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog(title, isPresented: $isPresented, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    destructiveAction()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(message)
            }
    }
}

extension View {
    func deleteConfirmation(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        action: @escaping () -> Void
    ) -> some View {
        modifier(DeleteConfirmationDialog(
            isPresented: isPresented,
            title: title,
            message: message,
            destructiveAction: action
        ))
    }
}