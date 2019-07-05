//
//  ReservationListInteractor.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-04.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import RxSwift

private struct ApiReservation {
    let reservationId: String
    let userId: String
    let vehicle: Vehicle
    let sharedSecret: String
    let isActive: Bool
    let notBeforeTimestamp: Double
    let expiryTimestamp: Double
    let vehicleLocation: Location
}

class DefaultReservationListInteractor: ReservationListInteractor {

    private let locationWorker: LocationWorker
    private let vehicleWorker: VehicleWorker

    init(locationWorker: LocationWorker, vehicleWorker: VehicleWorker) {
        self.locationWorker = locationWorker
        self.vehicleWorker = vehicleWorker
    }

    var activeLocation: Observable<Location> {
        return locationWorker.activeLocation
    }

    func findReservations() -> Observable<[Reservation]> {
        return Observable
            .combineLatest(fetchReservations(), vehicleWorker.nearbyVehicles)
            .map { reservations, nearbyVehicles in
                reservations.map { reservation in
                    let isNearby = nearbyVehicles.first(where: { $0.vehicleId == reservation.vehicle.vehicleId }) != nil
                    return Reservation(
                        reservationId: reservation.reservationId,
                        userId: reservation.userId,
                        vehicle: reservation.vehicle,
                        sharedSecret: reservation.sharedSecret,
                        isActive: reservation.isActive,
                        notBeforeTimestamp: reservation.notBeforeTimestamp, // 2018
                        expiryTimestamp: reservation.expiryTimestamp, // 2020
                        vehicleLocation: reservation.vehicleLocation,
                        isConnectable: isNearby
                    )
                }
            }

    }

    private func fetchReservations() -> Observable<[ApiReservation]> {
        return Observable.just([
            ApiReservation(
                reservationId: "r1",
                userId: "u1",
                vehicle: Vehicle(
                    vehicleId: "v1",
                    vehicleName: "1984 Ford Mustang"),
                sharedSecret: "my-lil-secret",
                isActive: true,
                notBeforeTimestamp: 1_528_126_066, // 2018
                expiryTimestamp: 1_591_284_466, // 2020
                vehicleLocation: Location(
                    latitude: 43.494_703_9,
                    longitude: -80.545_403_7,
                    name: "BSM Waterloo"))
        ])
    }

    func location(for reservationId: String) -> Observable<Location> {
        return Observable.just(Location(
            latitude: 43.494_703_9,
            longitude: -80.545_403_7,
            name: "BSM Waterloo"))
    }

    func claim(_ reservationId: String) -> Completable {
        return Completable.empty()
            .delay(.seconds(2), scheduler: MainScheduler.instance)
    }

}
