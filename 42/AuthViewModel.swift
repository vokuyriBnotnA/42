//
//  AuthViewModel.swift
//  42
//
//  Created by Anton on 14.12.2024.
//
import Foundation

class AuthViewModel: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiryDate: Date?

    init() {
        loadToken()
    }

    func saveToken(_ accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        self.isAuthorized = true

        // Сохранение в UserDefaults
        UserDefaults.standard.set(accessToken, forKey: "access_token")
        UserDefaults.standard.set(refreshToken, forKey: "refresh_token")
        UserDefaults.standard.set(tokenExpiryDate, forKey: "token_expiry_date")
    }

    func loadToken() {
        if let accessToken = UserDefaults.standard.string(forKey: "access_token"),
           let refreshToken = UserDefaults.standard.string(forKey: "refresh_token"),
           let expiryDate = UserDefaults.standard.object(forKey: "token_expiry_date") as? Date {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.tokenExpiryDate = expiryDate

            if Date() > expiryDate {
                refreshAccessToken()
            } else {
                self.isAuthorized = true
            }
        }
    }

    func refreshAccessToken() {
        guard let refreshToken = refreshToken else { return }
        let tokenURL = URL(string: "https://api.intra.42.fr/oauth/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"

        let clientID = Secrets.clientID
        let clientSecret = Secrets.clientSecret

        let bodyParams = [
            "grant_type": "refresh_token",
            "client_id": clientID,
            "client_secret": clientSecret,
            "refresh_token": refreshToken
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                print("HTTP ошибка: \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    self.isAuthorized = false
                }
                return
            }

            if let error = error {
                print("Ошибка: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isAuthorized = false
                }
                return
            }

            guard let data = data else {
                print("Данные не получены")
                DispatchQueue.main.async {
                    self.isAuthorized = false
                }
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let accessToken = json?["access_token"] as? String,
                   let refreshToken = json?["refresh_token"] as? String,
                   let expiresIn = json?["expires_in"] as? Int {
                    DispatchQueue.main.async {
                        self.saveToken(accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
                    }
                }
            } catch {
                print("Ошибка: \(error)")
                DispatchQueue.main.async {
                    self.isAuthorized = false
                }
            }
        }.resume()
    }

    func logout() {
        self.accessToken = nil
        self.refreshToken = nil
        self.tokenExpiryDate = nil
        self.isAuthorized = false

        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        UserDefaults.standard.removeObject(forKey: "token_expiry_date")
    }
}
