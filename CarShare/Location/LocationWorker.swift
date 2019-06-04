//
//  LocationWorker.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-04.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreLocation
import RxSwift

class LocationWorker: NSObject {

    private let subject = PublishSubject<CLLocation>()
    private let mainScheduler = MainScheduler.instance

    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        return locationManager
    }()

    var activeLocation: Observable<Location> {
        return subject
            .distinctUntilChanged { old, new in
                new.timestamp.timeIntervalSince1970 > old.timestamp.timeIntervalSince1970
            }
            .map { location in
                Location(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    name: "")
            }
            .do(
                onSubscribe: {
                    self.locationManager.requestWhenInUseAuthorization()
                    self.locationManager.startUpdatingLocation()
                }, onDispose: {
                    self.locationManager.stopUpdatingLocation()
                })
            .observeOn(mainScheduler)
    }
}

extension LocationWorker: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        subject.onNext(location)
    }
}
