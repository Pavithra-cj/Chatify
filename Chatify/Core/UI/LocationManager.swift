//
//  LocationManager.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-15.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    
    private var pendingCompletions: [(Result<CLLocation, LocationError>) -> Void] = []
    
    enum LocationError: Error {
        case denied
        case restricted
        case unavailable
        case timeout
    }
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .restricted, .denied:
            print("Location access denied")
        @unknown default:
            break
        }
    }
    
    func requestSingleLocation(timeout: TimeInterval = 10, completion: @escaping (Result<CLLocation, LocationError>) -> Void) {
        // If already have a reasonably recent location (< 30s), return immediately
        if let loc = location, abs(loc.timestamp.timeIntervalSinceNow) < 30 {
            completion(.success(loc))
            return
        }
        pendingCompletions.append(completion)
        requestLocation()
        // Setup timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            guard let self = self else { return }
            if !self.pendingCompletions.isEmpty {
                let completions = self.pendingCompletions
                self.pendingCompletions.removeAll()
                completions.forEach { $0(.failure(.timeout)) }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations.last
        locationManager.stopUpdatingLocation()
        let latest = locations.last
        if let latest = latest {
            let completions = pendingCompletions
            pendingCompletions.removeAll()
            completions.forEach { $0(.success(latest)) }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        completions.forEach { $0(.failure(.unavailable)) }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .denied, .restricted:
            let completions = pendingCompletions
            pendingCompletions.removeAll()
            completions.forEach { $0(.failure(manager.authorizationStatus == .denied ? .denied : .restricted)) }
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
}
