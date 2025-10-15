import SwiftUI

struct FlippableCardContainer: View {
    let fruit: Fruit
    @Binding var selectedImage: UIImage?
    @Binding var pickerSource: UIImagePickerController.SourceType
    var isCameraAvailable: Bool
    @ObservedObject var locationManager: LocationManager

    @State private var rotation = 0.0
    @State private var showingImagePicker = false
    @State private var showingRemoveConfirmation = false

    var body: some View {
        VStack {
            ZStack {
                // Show front or back depending on rotation
                if rotation.truncatingRemainder(dividingBy: 360) < 90 ||
                    rotation.truncatingRemainder(dividingBy: 360) > 270 {
                    frontContent
                        .onTapGesture { flipCard() }
                } else {
                    backContent
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)) // un-mirror
                        .onTapGesture { flipCard() }
                }
            }
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        .animation(.easeInOut(duration: 0.6), value: rotation)
        .frame(height: 350)
        .padding()
        .onAppear {
            DispatchQueue.main.async {
                rotation = 0
            }
        }
        .fullScreenCover(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: pickerSource, selectedImage: $selectedImage)
        }
        // ✅ Confirmation dialog for removing photo
        .confirmationDialog("Remove Photo?", isPresented: $showingRemoveConfirmation) {
            Button("Remove Photo", role: .destructive) {
                selectedImage = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove the selected photo?")
        }
    }

    // MARK: - Front
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

    // MARK: - Back
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
                    locationManager.requestLocation()
                    pickerSource = .photoLibrary
                    showingImagePicker = true
                }

                Button("Take Photo") {
                    guard isCameraAvailable else { return }
                    locationManager.requestLocation()
                    pickerSource = .camera
                    showingImagePicker = true
                }
                .disabled(!isCameraAvailable)
            }

            // ✅ Show Remove button only when an image exists
            if selectedImage != nil {
                Button(role: .destructive) {
                    showingRemoveConfirmation = true
                } label: {
                    Label("Remove Photo", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.95))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }

    // MARK: - Flip
    private func flipCard() {
        rotation += 180
    }
}

// MARK: - Preview
#Preview {
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

    @State var selectedImage: UIImage? = nil
    @State var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @StateObject var locationManager = LocationManager()

    return FlippableCardContainer(
        fruit: sampleFruit,
        selectedImage: $selectedImage,
        pickerSource: $pickerSource,
        isCameraAvailable: false,
        locationManager: locationManager
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
