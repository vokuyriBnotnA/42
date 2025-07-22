//
//  _2App.swift
//  42
//
//  Created by Anton on 06.12.2024.
//

import SwiftUI

@main
struct _2App: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var userCache = UserCache()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authViewModel.isAuthorized {
                    UserProfileView(accessToken: authViewModel.accessToken ?? "", authViewModel: authViewModel) .environmentObject(userCache)
                } else {
                    LoginView(authViewModel: authViewModel)
                }
            }
            .onOpenURL { url in
                handleRedirect(url: url, authViewModel: authViewModel)
            }
        }
    }

    func handleRedirect(url: URL, authViewModel: AuthViewModel) {
        guard url.absoluteString.starts(with: "myapp://auth/callback") else { return }

        if let queryItems = URLComponents(string: url.absoluteString)?.queryItems,
           let code = queryItems.first(where: { $0.name == "code" })?.value {
            exchangeCodeForToken(code, authViewModel: authViewModel)
        }
    }

    func exchangeCodeForToken(_ code: String, authViewModel: AuthViewModel) {
        let tokenURL = URL(string: "https://api.intra.42.fr/oauth/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"

        let clientID = Secrets.clientID
        let clientSecret = Secrets.clientSecret
        let redirectURI = "myapp://auth/callback"

        let bodyParams = [
            "grant_type": "authorization_code",
            "client_id": clientID,
            "client_secret": clientSecret,
            "code": code,
            "redirect_uri": redirectURI
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                print("HTTP error: \(httpResponse.statusCode)")
                return
            }

            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("no data")
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let accessToken = json?["access_token"] as? String,
                   let refreshToken = json?["refresh_token"] as? String,
                   let expiresIn = json?["expires_in"] as? Int {
                    DispatchQueue.main.async {
                        authViewModel.saveToken(accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
                    }
                }
            } catch {
                print("Error: \(error)")
            }
        }.resume()
    }

}
