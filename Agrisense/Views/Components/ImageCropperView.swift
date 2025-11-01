//
//  ImageCropperView.swift
//  Agrisense
//
//  Created by GitHub Copilot on 01/11/25.
//

import SwiftUI

struct ImageCropperView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let image: UIImage
    let onCrop: (UIImage) -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isProcessing = false
    @GestureState private var dragOffset: CGSize = .zero
    
    // Crop circle properties
    private let cropCircleSize: CGFloat = 280
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Cropping Area
                    ZStack {
                        // The image being cropped
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
                            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: offset)
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let delta = value / lastScale
                                            lastScale = value
                                            scale = min(max(scale * delta, 1.0), 4.0) // Limit zoom between 1x and 4x
                                        }
                                        .onEnded { _ in
                                            lastScale = 1.0
                                        },
                                    DragGesture()
                                        .updating($dragOffset) { value, state, _ in
                                            state = value.translation
                                        }
                                        .onEnded { value in
                                            offset.width += value.translation.width
                                            offset.height += value.translation.height
                                        }
                                )
                            )
                        
                        // Simple circular frame (no dark overlay)
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 3)
                            .frame(width: cropCircleSize, height: cropCircleSize)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 0)
                            .allowsHitTesting(false)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 500)
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: 12) {
                        Text(localizationManager.localizedString(for: "move_and_scale"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 24) {
                            Label {
                                Text(localizationManager.localizedString(for: "pinch_to_zoom"))
                            } icon: {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            Label {
                                Text(localizationManager.localizedString(for: "drag_to_move"))
                            } icon: {
                                Image(systemName: "hand.draw")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 32)
                }
                
                // Processing overlay
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(localizationManager.localizedString(for: "processing"))
                                .foregroundColor(.primary)
                        }
                        .padding(32)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 10)
                    }
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "crop_image"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localizedString(for: "cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: "choose")) {
                        cropImage()
                    }
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                    .disabled(isProcessing)
                }
            }
        }
    }
    
    private func cropImage() {
        isProcessing = true
        
        // Perform cropping on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let croppedImage = performCrop()
            
            DispatchQueue.main.async {
                isProcessing = false
                onCrop(croppedImage)
                dismiss()
            }
        }
    }
    
    private func performCrop() -> UIImage {
        let imageSize = image.size
        let imageScale = image.scale
        
        // Calculate the scale factor between screen points and image pixels
        let screenWidth = UIScreen.main.bounds.width
        let imageAspectRatio = imageSize.width / imageSize.height
        
        // Determine the display size of the image
        var displayWidth: CGFloat
        var displayHeight: CGFloat
        
        if imageAspectRatio > 1 {
            // Landscape image
            displayHeight = 500
            displayWidth = displayHeight * imageAspectRatio
        } else {
            // Portrait image
            displayWidth = screenWidth
            displayHeight = displayWidth / imageAspectRatio
        }
        
        // Scale factor from display points to image pixels
        let scaleFactorX = imageSize.width / displayWidth
        let scaleFactorY = imageSize.height / displayHeight
        
        // Calculate crop rect in image coordinates
        let cropSize = cropCircleSize * scaleFactorX / scale
        let cropX = (imageSize.width / 2) - (cropSize / 2) - (offset.width * scaleFactorX / scale)
        let cropY = (imageSize.height / 2) - (cropSize / 2) - (offset.height * scaleFactorY / scale)
        
        let cropRect = CGRect(x: cropX, y: cropY, width: cropSize, height: cropSize)
        
        // Perform the crop
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        let croppedUIImage = UIImage(cgImage: cgImage, scale: imageScale, orientation: image.imageOrientation)
        
        // Create circular mask
        return createCircularImage(from: croppedUIImage)
    }
    
    private func createCircularImage(from image: UIImage) -> UIImage {
        let size = min(image.size.width, image.size.height)
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        
        // Create circular path
        context.addEllipse(in: rect)
        context.clip()
        
        // Draw image
        let drawRect = CGRect(
            x: (size - image.size.width) / 2,
            y: (size - image.size.height) / 2,
            width: image.size.width,
            height: image.size.height
        )
        image.draw(in: drawRect)
        
        guard let circularImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return image
        }
        
        return circularImage
    }
}

// Preview
struct ImageCropperView_Previews: PreviewProvider {
    static var previews: some View {
        ImageCropperView(image: UIImage(systemName: "person.circle.fill")!) { _ in }
            .environmentObject(LocalizationManager.shared)
    }
}
