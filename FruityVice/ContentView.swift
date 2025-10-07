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
 
    // Store selected images per fruit (by fruit name or id)
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
                        if fruitImages[fruit.name] != nil {
                            Image(uiImage: fruitImages[fruit.name]!)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .navigationTitle("Fruits")
            .task { await loadFruits() }
            // Present sheet for selected fruit
            .sheet(item: $selectedFruit) { fruit in
                // Create a binding specific to this fruit
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
 
#Preview {
    ContentView()
}
