//
//  LoginView.swift
//  42
//
//  Created by Anton on 14.12.2024.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel

    var body: some View {
        VStack {
            Text("Welcome!")
                .font(.headline)
                .padding()

            Button(action: startOAuthFlow) {
                Text("Login 42")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding()
        }
    }

    func startOAuthFlow() {
        let clientID = Secrets.clientID
        let redirectURI = "myapp://auth/callback"
        let state = UUID().uuidString
        let authURL = "https://api.intra.42.fr/oauth/authorize"

        let urlString = "\(authURL)?client_id=\(clientID)&redirect_uri=\(redirectURI)&response_type=code&scope=public&state=\(state)&prompt=login"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
