//
//  FileAttachmentViews.swift
//  Agrisense
//
//  Created by Athar Reza on 30/09/25.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - File Picker View

struct FilePickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onFilePicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .pdf,
            .text,
            .plainText,
            .image,
            .jpeg,
            .png,
            UTType(filenameExtension: "docx") ?? .data,
            UTType(filenameExtension: "pptx") ?? .data,
            UTType(filenameExtension: "doc") ?? .data,
            UTType(filenameExtension: "ppt") ?? .data
        ], asCopy: true)
        
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilePickerView
        
        init(_ parent: FilePickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onFilePicked(url)
            }
            parent.isPresented = false
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Photo Picker View

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
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
            if let result = results.first {
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.onImagePicked(image)
                        }
                    }
                }
            }
            parent.isPresented = false
        }
    }
}

// MARK: - Attachment Display View

struct AttachmentDisplayView: View {
    let attachment: MessageAttachment
    @State private var showingFullScreen = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Attachment icon or thumbnail
                Group {
                    if let thumbnailData = attachment.thumbnailData,
                       let image = UIImage(data: thumbnailData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .cornerRadius(6)
                    } else {
                        Image(systemName: attachment.type.icon)
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(attachment.fileName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(attachment.fileSize.formattedFileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if attachment.type == .image {
                        Text("Tap to view full size")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                if attachment.type == .image {
                    Button("View") {
                        showingFullScreen = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // Show extracted text preview if available
            if let extractedText = attachment.extractedText, !extractedText.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Extracted Text:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(extractedText)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(4)
                }
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
        .onTapGesture {
            if attachment.type == .image {
                showingFullScreen = true
            }
        }
        .sheet(isPresented: $showingFullScreen) {
            if attachment.type == .image {
                FullScreenImageView(attachment: attachment)
            }
        }
    }
}

// MARK: - Full Screen Image View

struct FullScreenImageView: View {
    let attachment: MessageAttachment
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if let imageData = try? Data(contentsOf: URL(fileURLWithPath: attachment.url)),
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color.black)
                } else {
                    Text("Image could not be loaded")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(attachment.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - File Attachment Action Sheet

struct FileAttachmentActionSheet: View {
    @Binding var isPresented: Bool
    let onCameraSelected: () -> Void
    let onPhotoLibrarySelected: () -> Void
    let onDocumentSelected: () -> Void
    
    var body: some View {
        // Present a modern confirmation dialog instead of returning ActionSheet directly
        EmptyView()
            .confirmationDialog(
                "Add Attachment",
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button("Take Photo", action: onCameraSelected)
                Button("Choose from Library", action: onPhotoLibrarySelected)
                Button("Browse Documents", action: onDocumentSelected)
                Button("Cancel", role: .cancel) {}
            }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}