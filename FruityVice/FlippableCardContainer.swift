//
//  FlippableCardContainer.swift
//  FruityVice
//
//  Created by Douglas Jasper on 2025-10-06.
//

import SwiftUI

struct FlippableCardContainer: View {
    let fruit: Fruit

    // Bindings from parent view
    @Binding var selectedImage: UIImage?
    @Binding var showingImagePicker: Bool
    @Binding var pickerSource: UIImagePickerController.SourceType
    var isCameraAvailable: Bool

    // Local rotation state
    @State private var rotation = 0.0

    var body: some View {
        VStack {
            ZStack {
                // Determine front/back based on rotation
                if rotation.truncatingRemainder(dividingBy: 360) < 90 ||
                   rotation.truncatingRemainder(dividingBy: 360) > 270 {
                    frontContent
                        .onTapGesture { flipCard() }
                } else {
                    backContent
                        .rotation3DEffect(.degrees(180), axis: (x:0, y:1, z:0)) // fix mirrored back
                        .onTapGesture { flipCard() }
                }
            }
        }
        .rotation3DEffect(.degrees(rotation), axis: (x:0, y:1, z:0))
        .animation(.easeInOut(duration: 0.6), value: rotation)
        .frame(height: 350)
        .padding()
        .onAppear {
            rotation = 0  // Ensure front side is visible on first appearance
        }
    }

    // MARK: - Front side content
    private var frontContent: some View {
        VStack(spacing: 10) {
            Text(fruit.name)
                .font(.title)
                .bold()
            Text(fruit.family)
                .foregroundColor(.secondary)
            Text("Calories: \(fruit.nutritions.calories)")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }

    // MARK: - Back side content
    private var backContent: some View {
        VStack(spacing: 10) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
            } else {
                Text("No Image Selected")
                    .foregroundColor(.gray)
            }

            HStack(spacing: 20) {
                Button("Pick from Library") {
                    pickerSource = .photoLibrary
                    DispatchQueue.main.async { showingImagePicker = true }
                }

                Button("Take Photo") {
                    guard isCameraAvailable else { return }
                    pickerSource = .camera
                    DispatchQueue.main.async { showingImagePicker = true }
                }
                .disabled(!isCameraAvailable)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.95))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }

    // MARK: - Flip action
    private func flipCard() {
        rotation += 180
    }
}

#Preview {
    // Sample fruit for preview
    let sampleFruit = Fruit(
        name: "Apple",
        genus: "Malus",
        family: "Rosaceae",
        order: "Rosales",
        nutritions: Nutrition(
            carbohydrates: 13.81,
            protein: 0.26,
            fat: 0.17,
            calories: 52,
            sugar: 10.39
        )
    )

    // Mock state variables for bindings
    @State var selectedImage: UIImage? = nil
    @State var showingImagePicker = false
    @State var pickerSource: UIImagePickerController.SourceType = .photoLibrary

    return FlippableCardContainer(
        fruit: sampleFruit,
        selectedImage: $selectedImage,
        showingImagePicker: $showingImagePicker,
        pickerSource: $pickerSource,
        isCameraAvailable: false // disable camera for preview
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
