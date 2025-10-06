//
//  FlippableCardContainer.swift
//  FruityVice
//
//  Created by Douglas Jasper on 2025-10-06.
//

import SwiftUI

struct FlippableCardContainer: View {
    let fruit: Fruit

    // Bindings from parent
    @Binding var selectedImage: UIImage?
    @Binding var showingImagePicker: Bool
    @Binding var pickerSource: UIImagePickerController.SourceType
    var isCameraAvailable: Bool

    @State private var rotation = 0.0

    var body: some View {
        VStack {
            ZStack {
                if rotation.truncatingRemainder(dividingBy: 360) < 90 ||
                   rotation.truncatingRemainder(dividingBy: 360) > 270 {
                    frontContent
                        .onTapGesture { flipCard() }
                } else {
                    backContent
                        .rotation3DEffect(.degrees(180), axis: (x:0, y:1, z:0))
                        .onTapGesture { flipCard() }
                }
            }
        }
        .rotation3DEffect(.degrees(rotation), axis: (x:0, y:1, z:0))
        .animation(.easeInOut(duration: 0.6), value: rotation)
        .frame(height: 350)
        .padding()
        .onAppear { rotation = 0 }
    }

    // Front side of the card
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

    // Back side of the card
    private var backContent: some View {
        VStack(spacing: 10) {
            if let image = selectedImage {
                Image(uiImage:image)
                    .resizable()
                    .scaledToFit()
                    .frame(height:200)
                    .cornerRadius(10)
            } else {
                Text("No Image Selected")
                    .foregroundColor(.gray)
            }

            HStack(spacing: 20) {
                Button("Pick from Library") {
                    pickerSource = .photoLibrary
                    showingImagePicker = true // only trigger parent sheet
                }

                Button("Take Photo") {
                    guard isCameraAvailable else { return }
                    pickerSource = .camera
                    showingImagePicker = true // only trigger parent sheet
                }
                .disabled(!isCameraAvailable)
            }
        }
        .frame(maxWidth:.infinity, maxHeight:.infinity)
        .background(Color(white:0.95))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }

    private func flipCard() { rotation += 180 }
}

// Preview
#Preview {
    let sampleFruit = Fruit(
        name: "Apple",
        genus: "Malus",
        family: "Rosaceae",
        order: "Rosales",
        nutritions: Nutrition(carbohydrates: 13.81, protein: 0.26, fat: 0.17, calories: 52, sugar: 10.39)
    )
    @State var selectedImage: UIImage? = nil
    @State var showingImagePicker = false
    @State var pickerSource: UIImagePickerController.SourceType = .photoLibrary

    return FlippableCardContainer(
        fruit: sampleFruit,
        selectedImage: $selectedImage,
        showingImagePicker: $showingImagePicker,
        pickerSource: $pickerSource,
        isCameraAvailable: false
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
