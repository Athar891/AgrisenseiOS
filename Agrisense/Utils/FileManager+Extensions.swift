//
//  FileManager+Extensions.swift
//  Agrisense
//
//  Created by Athar Reza on 30/09/25.
//

import Foundation
import UIKit
import UniformTypeIdentifiers
import PDFKit
import Vision

// MARK: - File Management Extensions

extension FileManager {
    static let assistantDocumentsURL: URL = {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let assistantURL = documentsURL.appendingPathComponent("AssistantFiles")
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: assistantURL.path) {
            try? FileManager.default.createDirectory(at: assistantURL, withIntermediateDirectories: true)
        }
        
        return assistantURL
    }()
    
    static func saveAttachmentFile(_ data: Data, withName fileName: String) -> URL? {
        let fileURL = assistantDocumentsURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save attachment file: \(error)")
            return nil
        }
    }
    
    static func deleteAttachmentFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    static func attachmentFileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
}

// MARK: - File Processing Utilities

class FileProcessor {
    static let shared = FileProcessor()
    
    private init() {}
    
    func processFile(at url: URL) async -> MessageAttachment? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        let fileName = url.lastPathComponent
        let fileSize = Int64(data.count)
        let mimeType = mimeType(for: url)
        let attachmentType = determineAttachmentType(from: mimeType)
        
        // Save file locally
        let fileNameWithTimestamp = "\(Date().timeIntervalSince1970)_\(fileName)"
        guard let localURL = FileManager.saveAttachmentFile(data, withName: fileNameWithTimestamp) else {
            return nil
        }
        
        // Generate thumbnail for images
        var thumbnailData: Data?
        if attachmentType == .image {
            thumbnailData = await generateImageThumbnail(from: data)
        }
        
        // Extract text from documents
        var extractedText: String?
        switch attachmentType {
        case .image:
            extractedText = await extractTextFromImage(data: data)
        case .pdf:
            extractedText = await extractTextFromPDF(at: url)
        case .document:
            extractedText = await extractTextFromDocument(at: url)
        default:
            break
        }
        
        return MessageAttachment(
            type: attachmentType,
            url: localURL.path,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: mimeType,
            thumbnailData: thumbnailData,
            extractedText: extractedText
        )
    }
    
    private func mimeType(for url: URL) -> String {
        if let type = UTType(filenameExtension: url.pathExtension) {
            return type.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }
    
    private func determineAttachmentType(from mimeType: String) -> MessageAttachment.AttachmentType {
        for type in MessageAttachment.AttachmentType.allCases {
            if type.supportedMimeTypes.contains(mimeType) {
                return type
            }
        }
        return .document
    }
    
    @MainActor
    private func generateImageThumbnail(from data: Data) async -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        
        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        return thumbnail.jpegData(compressionQuality: 0.8)
    }
    
    private func extractTextFromImage(data: Data) async -> String? {
        guard let cgImage = UIImage(data: data)?.cgImage else { return nil }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            let observations = request.results ?? []
            let extractedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            return extractedText.isEmpty ? nil : extractedText
        } catch {
            print("Text recognition error: \(error)")
            return nil
        }
    }
    
    private func extractTextFromPDF(at url: URL) async -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        
        var text = ""
        for pageIndex in 0..<document.pageCount {
            if let page = document.page(at: pageIndex) {
                text += page.string ?? ""
                text += "\n\n"
            }
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text
    }
    
    private func extractTextFromDocument(at url: URL) async -> String? {
        // For now, return a placeholder. In a full implementation, you would use
        // a library like the Microsoft Office SDK or convert to PDF first
        return "Document text extraction not yet implemented for this file type."
    }
}

// MARK: - File Size Formatter

extension Int64 {
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self)
    }
}