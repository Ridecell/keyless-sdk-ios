//
//  LoginHelper.swift
//  Keyless_Example
//
//  Created by Alex Blokker on 12/4/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import Keyless

class LoginHelper {
    
    let logger: Logger
    let loginURL = URL(string: "https://bear-qa.ridecell.us/api/v2/authenticate")!
    let rentalURL = URL(string: "https://bear-qa.ridecell.us/api/v2/rentals/?in_progress=true")!
    let developerToken = "JWT eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJ0ZW5hbnRfaWQiOiJiZWFyLXFhIiwiZGV2ZWxvcGVyX2dyb3VwIjoib3duZXIiLCJqdGkiOiJhNzk2NjJmNi0yYjdlLTRkYTEtODFlZC1jZDg4YmQ3MTk4N2IiLCJuYmYiOjE1OTAwNzkzNzEsImlzX3ZhbGlkIjp0cnVlLCJleHAiOjE3NDc3NTkzNzEsInJlZ2lvbiI6IlVTIn0.r8n8RcMwBumpl5bzCVzHTaC7QYTjgSH786QuAsosVgkJEBmSzDnjCTuXKqyWzGPgrl4gAKgsU-PZQ3MLT-GAAn3JpRZidFwwlJ638mzDuGuBjRhgzArtDXtquJxfOuFOZ6UmQqaSFMG3v_Msk2wGHUXpHcA5Jp66Hw7eIL5T-H-SAzaiwS8SDZ8By5Yu_3IeKOO3SvrUOmn5zSwCgdaLpf0tbkXTSMi6-GoJYn5g3MTwScldYlzlWLO8SEWWKgNgfdsv5w6Xtie_05VMIoelT7pwA4z6DDCBpZlpRfATnYnzrX65KNfmrwkSrHLKgcyBEZxymjh8ZfIUStk7tJlZnfYKiatCppE3lw34NEezgzH6UBniE4z3Khw5scGpH73jBa0f9v0b5Ugn069Pke3xQtTYmNQXv85Ccz7ZRDDNC0SDCbmAV9GwMN2wQ4AOKnRqdG4kAf2GutsNig0bZbh3duAYDW6zyv1mPEmcz9clbrEpkpgEt778dPyTJ8oNcq7Z-qVzFyo8ed_TcdaAujG9CKSeBz-np4dKW-c7KnhBh7H58bJGynxU-Unx_dr_EK1q3bdlGnV8TK62A8Z0t6YP5jOX1jb6x73qhxMlzvcpVY5pgWDwDokVdlPE9lJgSQoonVwpQg2gC2fzcQe9ukOIonL2qlE_IFeeFGQku6V6AdQ"

    init(logger: Logger) {
        self.logger = logger
    }

    public func getEventId(email: String, password: String, complete: @escaping (String) -> ()) {
        getAuthToken(for: email, password: password) { (authToken) in
            guard !authToken.isEmpty else {
                complete("") // not now, empty just means error
                return
            }
            self.getEventId(for: authToken, complete: complete)
        }
    }

    private func getAuthToken(for email: String, password: String, complete: @escaping (String) -> ()) {
        var urlRequest = URLRequest(url: loginURL)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue(developerToken, forHTTPHeaderField: "Developer-Token")
        urlRequest.httpMethod = "POST"
        let params = ["username": email, "password": password]
        urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
        logger.d("Getting auth_token")
        logger.d("POST \(loginURL)")
        
        func completeMain(_ token: String) {
            DispatchQueue.main.async {
                complete(token)
            }
        }
        
        let time = Date()
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, (response as? HTTPURLResponse)?.statusCode == 200 else {
                // bad response
                self.logger.d("Getting auth_token: Error, took \(-time.timeIntervalSinceNow)s")
                completeMain("")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                guard let token = (json as? [String: Any])?["auth_token"] as? String else {
                    self.logger.d("Getting auth_token: Error, took \(-time.timeIntervalSinceNow)s")
                    completeMain("")
                    return
                }
                self.logger.d("Getting auth_token: Success, took \(-time.timeIntervalSinceNow)s")
                completeMain(token)
            } catch {
                // throw error
                self.logger.d("Getting auth_token: Error, took \(-time.timeIntervalSinceNow)s")
                completeMain("")
            }
        }.resume()
    }
        
    private func getEventId(for token: String, complete: @escaping (String) -> ()) {
        var urlRequest = URLRequest(url: rentalURL)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("JWT \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.httpMethod = "GET"

        logger.d("Getting ble_event_id")
        logger.d("GET \(rentalURL)")
        
        func completeMain(_ token: String) {
            DispatchQueue.main.async {
                complete(token)
            }
        }
        let time = Date()
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, (response as? HTTPURLResponse)?.statusCode == 200 else {
                // bad response
                self.logger.d("Getting ble_event_id: Error, took \(-time.timeIntervalSinceNow)s")
                completeMain("")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                guard let results = (json as? [String: Any])?["results"] as? [[String: Any]], let firstResult = results.first else {
                    self.logger.d("Getting ble_event_id: Error, took \(-time.timeIntervalSinceNow)s")
                    completeMain("")
                    return
                }
                let bleEventId = firstResult["ble_event_id"] as? String
                self.logger.d("Getting ble_event_id: Success, took \(-time.timeIntervalSinceNow)s")
                completeMain(bleEventId ?? "")
            } catch {
                // throw error
                completeMain("")
                self.logger.d("Getting ble_event_id: Error, took \(-time.timeIntervalSinceNow)s")
            }
        }.resume()
    }
}
