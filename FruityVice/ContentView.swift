//
//  ContentView.swift
//  FruityVice
//
//  Created by Douglas Jasper on 2025-10-06.
//

import SwiftUI
import PDFKit

struct ContentView: View {
    @State private var fruits: [Fruit] = []
    @State private var selectedFruit: Fruit? = nil

    // Store selected images per fruit (by fruit name)
    @State private var fruitImages: [String: UIImage] = [:]

    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationView {
            List(fruits) { fruit in
                Button(action: {
                    selectedFruit = fruit
                }) {
                    HStack {
                        Text(fruit.name)
                        Spacer()
                        if let image = fruitImages[fruit.name] {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .navigationTitle("Fruits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save PDF") {
                        savePDFReport()
                    }
                }
            }
            .task { await loadFruits() }
            .sheet(item: $selectedFruit) { fruit in
                let binding = Binding<UIImage?>(
                    get: { fruitImages[fruit.name] },
                    set: { fruitImages[fruit.name] = $0 }
                )

                FlippableCardContainer(
                    fruit: fruit,
                    selectedImage: binding,
                    pickerSource: $pickerSource,
                    isCameraAvailable: isCameraAvailable
                )
                .id(fruit.id)
            }
        }
    }

    // MARK: - Load Fruits
    func loadFruits() async {
        guard let url = URL(string: "https://www.fruityvice.com/api/fruit/all") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([Fruit].self, from: data)
            DispatchQueue.main.async {
                fruits = decoded
            }
        } catch {
            print("Error loading fruits:", error)
        }
    }

    // MARK: - Save PDF Report
    func savePDFReport() {
        let pdfMetaData = [
            kCGPDFContextCreator: "Fruity App",
            kCGPDFContextAuthor: "Your Name"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 612.0
        let pageHeight = 792.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            for fruit in fruits {
                guard let image = fruitImages[fruit.name] else { continue }
                context.beginPage()

                // Draw fruit text
                let textAttributes = [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
                ]
                let text = "\(fruit.name)\nFamily: \(fruit.family)\nCalories: \(fruit.nutritions.calories)"
                let textRect = CGRect(x: 20, y: 20, width: pageWidth - 40, height: 100)
                text.draw(in: textRect, withAttributes: textAttributes)

                // Draw image
                let imageMaxWidth = pageWidth - 40
                let imageMaxHeight = pageHeight - 150
                let aspectRatio = image.size.width / image.size.height
                var imageWidth = imageMaxWidth
                var imageHeight = imageWidth / aspectRatio
                if imageHeight > imageMaxHeight {
                    imageHeight = imageMaxHeight
                    imageWidth = imageHeight * aspectRatio
                }
                let imageRect = CGRect(
                    x: (pageWidth - imageWidth)/2,
                    y: 120,
                    width: imageWidth,
                    height: imageHeight
                )
                image.draw(in: imageRect)
            }
        }

        // Present share sheet
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("FruitsReport.pdf")
        do {
            try data.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Could not save PDF: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
