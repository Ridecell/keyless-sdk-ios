//
//  ReservationListModule.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-04.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import Swinject

enum ReservationListModule: Module {
    static func register(in container: Container) {
        container.register(ReservationListView.self) { r in
            ReservationListViewController.initialize(presenter: r.resolve(ReservationListPresenter.self)!)
        }
        container.register(ReservationListPresenter.self) { r in
            DefaultReservationListPresenter(
                interactor: r.resolve(ReservationListInteractor.self)!,
                router: r.resolve(ReservationListRouter.self)!)
        }
        container.register(ReservationListInteractor.self) { r in
            DefaultReservationListInteractor(
                locationWorker: r.resolve(LocationWorker.self)!,
                vehicleWorker: r.resolve(VehicleWorker.self)!)
        }
        container.register(ReservationListRouter.self) { _ in
            NoopRouter()
        }
    }
}

private class NoopRouter: ReservationListRouter {
    func goToReservationPage(for reservationId: String) {
        log.info("Route to reservation \(reservationId)")
    }
}
