import SwiftUI
import UIKit
import PhotosUI
import VisionKit

// MARK: - Image Picker for AI Calendar Processing
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageSelected(image)
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Photo Picker using PhotosUI
@available(iOS 16.0, *)
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            self.parent.selectedImage = image
                            self.parent.onImageSelected(image)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Image Selection Sheet with Options
struct ImageSelectionSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    let onImageSelected: (UIImage) -> Void
    
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showDocumentScanner = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Add Calendar Image")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("Take a photo or select an image of a calendar, schedule, or event details. I'll help you extract and create events from it.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    // Camera Option
                    ImageSourceButton(
                        title: "Take Photo",
                        subtitle: "Use camera to capture calendar",
                        icon: "camera.fill",
                        color: .blue
                    ) {
                        showCamera = true
                    }
                    
                    // Photo Library Option
                    ImageSourceButton(
                        title: "Choose from Photos",
                        subtitle: "Select existing calendar image",
                        icon: "photo.on.rectangle",
                        color: .green
                    ) {
                        showPhotoLibrary = true
                    }
                    
                    // Document Scanner Option (iOS 13+)
                    if #available(iOS 13.0, *) {
                        ImageSourceButton(
                            title: "Scan Document",
                            subtitle: "Scan calendar with document scanner",
                            icon: "doc.text.viewfinder",
                            color: .orange
                        ) {
                            showDocumentScanner = true
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Calendar Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                ImagePicker(
                    selectedImage: $selectedImage,
                    isPresented: $showCamera,
                    sourceType: .camera,
                    onImageSelected: onImageSelected
                )
            }
        }
        .sheet(isPresented: $showPhotoLibrary) {
            if #available(iOS 16.0, *) {
                PhotoPickerView(
                    selectedImage: $selectedImage,
                    isPresented: $showPhotoLibrary,
                    onImageSelected: onImageSelected
                )
            } else {
                ImagePicker(
                    selectedImage: $selectedImage,
                    isPresented: $showPhotoLibrary,
                    sourceType: .photoLibrary,
                    onImageSelected: onImageSelected
                )
            }
        }
        .sheet(isPresented: $showDocumentScanner) {
            if #available(iOS 13.0, *) {
                DocumentScannerView(
                    selectedImage: $selectedImage,
                    isPresented: $showDocumentScanner,
                    onImageSelected: onImageSelected
                )
            }
        }
    }
}

// MARK: - Image Source Button Component
struct ImageSourceButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Document Scanner (iOS 13+)
@available(iOS 13.0, *)
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            if scan.pageCount > 0 {
                let image = scan.imageOfPage(at: 0)
                parent.selectedImage = image
                parent.onImageSelected(image)
            }
            parent.isPresented = false
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document scanner error: \(error)")
            parent.isPresented = false
        }
    }
}