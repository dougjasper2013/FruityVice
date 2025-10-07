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

    // Image picker state (top-level)
    @State private var selectedImage: UIImage? = nil
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationView {
            List(fruits) { fruit in
                Button(action: {
                    // set the selected fruit; sheet(item:) will present
                    selectedFruit = fruit
                }) {
                    Text(fruit.name)
                }
            }
            .navigationTitle("Fruits")
            .task { await loadFruits() }
            // Present the card sheet directly bound to the selectedFruit item
            .sheet(item: $selectedFruit) { fruit in
                FlippableCardContainer(
                    fruit: fruit,
                    selectedImage: $selectedImage,
                    pickerSource: $pickerSource,
                    isCameraAvailable: isCameraAvailable
                )
                .id(fruit.id) // force fresh instance for each fruit
            }
        }
    }

    // Fetch Fruityvice data
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
