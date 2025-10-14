import SwiftUI
import PDFKit
import MapKit

// MARK: - Struct to store image + timestamp + location
struct FruitImageInfo: Codable {
    var filename: String
    var date: Date
    var address: String?
    var latitude: Double?
    var longitude: Double?
}

struct ContentView: View {
    @State private var fruits: [Fruit] = []
    @State private var selectedFruit: Fruit? = nil
    
    // Store selected images per fruit
    @State private var fruitImages: [String: UIImage] = [:]
    @State private var fruitImageInfo: [String: FruitImageInfo] = [:]
    
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @StateObject private var locationManager = LocationManager()
    
    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    private var imageInfoURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FruitImageInfo.json")
    }
    
    var body: some View {
        NavigationView {
            List(fruits, id: \.name) { fruit in
                Button(action: { selectedFruit = fruit }) {
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
                        Task { await savePDFReport() }
                    }
                }
            }
            .task {
                await loadFruits()
                loadSavedImages()
            }
            .sheet(item: $selectedFruit) { fruit in
                let binding = Binding<UIImage?>(
                    get: { fruitImages[fruit.name] },
                    set: {
                        if let newImage = $0 {
                            fruitImages[fruit.name] = newImage
                            saveImage(newImage, for: fruit)
                        } else {
                            fruitImages[fruit.name] = nil
                            deleteImage(for: fruit)
                        }
                    }
                )
                
                FlippableCardContainer(
                    fruit: fruit,
                    selectedImage: binding,
                    pickerSource: $pickerSource,
                    isCameraAvailable: isCameraAvailable,
                    locationManager: locationManager
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
            DispatchQueue.main.async { fruits = decoded }
        } catch {
            print("Error loading fruits:", error)
        }
    }
    
    // MARK: - Image Persistence
    func saveImage(_ image: UIImage, for fruit: Fruit) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let filename = "\(fruit.name).jpg"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            fruitImages[fruit.name] = image
            
            // Capture location info
            let address = locationManager.currentAddress
            let latitude = locationManager.lastLocation?.coordinate.latitude
            let longitude = locationManager.lastLocation?.coordinate.longitude
            
            fruitImageInfo[fruit.name] = FruitImageInfo(
                filename: filename,
                date: Date(),
                address: address,
                latitude: latitude,
                longitude: longitude
            )
            
            saveImageInfo()
        } catch {
            print("Failed to save image: \(error)")
        }
    }
    
    func deleteImage(for fruit: Fruit) {
        fruitImages[fruit.name] = nil
        fruitImageInfo[fruit.name] = nil
        saveImageInfo()
    }
    
    func saveImageInfo() {
        do {
            let data = try JSONEncoder().encode(fruitImageInfo)
            try data.write(to: imageInfoURL)
        } catch {
            print("Error saving image info:", error)
        }
    }
    
    func loadSavedImages() {
        guard let data = try? Data(contentsOf: imageInfoURL),
              let savedInfo = try? JSONDecoder().decode([String: FruitImageInfo].self, from: data)
        else { return }
        
        fruitImageInfo = savedInfo
        
        for (fruitName, info) in savedInfo {
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(info.filename)
            if let imageData = try? Data(contentsOf: fileURL),
               let image = UIImage(data: imageData) {
                fruitImages[fruitName] = image
            }
        }
    }
    
    // MARK: - Save PDF Report (with Map Snapshots)
    func savePDFReport() async {
        let pageWidth = 612.0
        let pageHeight = 792.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // Generate map snapshots for fruits with coordinates
        var snapshots: [String: UIImage] = [:]
        for (fruitName, info) in fruitImageInfo {
            if let lat = info.latitude, let lon = info.longitude {
                let options = MKMapSnapshotter.Options()
                options.region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
                options.size = CGSize(width: 300, height: 200)
                let snapshotter = MKMapSnapshotter(options: options)
                if let snapshot: MKMapSnapshotter.Snapshot = try? await snapshotter.start() {
                    snapshots[fruitName] = snapshot.image
                }
            }
        }
        
        // Generate PDF synchronously
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "Fruity App",
            kCGPDFContextAuthor as String: "Your Name"
        ]
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            for fruit in fruits {
                guard let image = fruitImages[fruit.name],
                      let info = fruitImageInfo[fruit.name] else { continue }
                
                context.beginPage()
                
                let textAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                let dateString = formatter.string(from: info.date)
                
                let text = """
                Name: \(fruit.name)
                Family: \(fruit.family)
                Genus: \(fruit.genus)
                Order: \(fruit.order)
                Photo Date: \(dateString)
                Address: \(info.address ?? "Unknown Address")
                """
                
                text.draw(in: CGRect(x: 20, y: 20, width: pageWidth - 40, height: 120),
                          withAttributes: textAttributes)
                
                // Draw fruit image
                let maxWidth = pageWidth - 40
                let maxHeight = pageHeight - 300
                let aspectRatio = image.size.width / image.size.height
                var imgWidth = maxWidth
                var imgHeight = imgWidth / aspectRatio
                if imgHeight > maxHeight {
                    imgHeight = maxHeight
                    imgWidth = imgHeight * aspectRatio
                }
                
                let imgRect = CGRect(x: (pageWidth - imgWidth)/2,
                                     y: 150,
                                     width: imgWidth,
                                     height: imgHeight)
                image.draw(in: imgRect)
                
                // Draw map snapshot if available
                if let mapImage = snapshots[fruit.name] {
                    let mapRect = CGRect(x: (pageWidth - 300)/2,
                                         y: imgRect.maxY + 10,
                                         width: 300,
                                         height: 200)
                    mapImage.draw(in: mapRect)
                }
            }
        }
        
        // Present share sheet
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("FruitReport.pdf")
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
