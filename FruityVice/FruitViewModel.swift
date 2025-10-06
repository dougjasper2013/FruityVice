//
//  FruitViewModel.swift
//  FruityVice
//
//  Created by Douglas Jasper on 2025-10-06.
//

import Foundation
import Combine

class FruitViewModel: ObservableObject {
    @Published var fruits: [Fruit] = []
    
    func fetchFruits() {
        guard let url = URL(string: "https://www.fruityvice.com/api/fruit/all") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data else { return }
            
            do {
                let fruits = try JSONDecoder().decode([Fruit].self, from: data)
                DispatchQueue.main.async {
                    self.fruits = fruits
                }
            } catch {
                print("Error decoding: \(error)")
            }
        }.resume()
    }
}
