//
//  LocationManager.swift
//  FruityVice
//
//  Created by Douglas Jasper on 2025-10-08.
//

import Foundation
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentAddress: String? = nil

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var components: [String] = []
                if let street = placemark.thoroughfare { components.append(street) }
                if let city = placemark.locality { components.append(city) }
                if let state = placemark.administrativeArea { components.append(state) }
                if let postal = placemark.postalCode { components.append(postal) }
                self.currentAddress = components.joined(separator: ", ")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location:", error)
    }
}
