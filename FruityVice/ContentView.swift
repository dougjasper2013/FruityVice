//
//  ContentView.swift
//  FruityVice
//
//  Created by Douglas Jasper on 2025-10-06.
//

import SwiftUI

struct ContentView: View {
    @State private var fruits: [Fruit] = []
    @State private var selectedFruit: Fruit? = nil
    @State private var showCard = false

    // Image picker state
    @State private var selectedImage: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationView {
            List(fruits) { fruit in
                Button(fruit.name) {
                    selectedFruit = fruit
                    showCard = true
                }
            }
            .navigationTitle("Fruits")
            .task {
                await loadFruits()
            }
            // Card sheet
            .sheet(isPresented: $showCard) {
                if let fruit = selectedFruit {
                    FlippableCardContainer(
                        fruit: fruit,
                        selectedImage: $selectedImage,
                        showingImagePicker: $showingImagePicker,
                        pickerSource: $pickerSource,
                        isCameraAvailable: isCameraAvailable
                    )
                }
            }
            // Image picker sheet (single sheet, resolves multiple sheet issue)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: pickerSource, selectedImage: $selectedImage)
            }
        }
    }

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
}

// Preview
#Preview {
    ContentView()
}
