//
//  APIService.swift
//  42
//
//  Created by Anton on 07.12.2024.
//

import OAuth2
import Foundation

class OAuthService {
    private let oauth2: OAuth2ClientCredentials
    
    init() {
        // Конфигурация клиента
        let settings = [
            "client_id": Secrets.clientID,
            "client_secret": Secrets.clientSecret,
            "token_uri": "https://api.intra.42.fr/oauth/token",
            "scope": "",
            "keychain": true
        ] as OAuth2JSON
        
        // Создаем OAuth2 клиент
        self.oauth2 = OAuth2ClientCredentials(settings: settings)
    }
    
    // Получение токена
    func getAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        oauth2.authorize { json, error in
            if let json = json,
               let token = json["access_token"] as? String {
                completion(.success(token))
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "OAuth2", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected response"])))
            }
        }
    }
}

enum APIError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
}

class APIService {
    private let accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    func searchUsers(query: String, page: Int, completion: @escaping (Result<[UserDetails], Error>) -> Void) {
        
        let urlString = "https://api.intra.42.fr/v2/users?filter[login]=\(query)&page=\(page)"
        
        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString) else {
            completion(.failure(NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data {
                do {
                    let users = try JSONDecoder().decode([UserDetails].self, from: data) // Декодирование пользователей
                    print("Users after search: \(users)")
                    completion(.success(users))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Метод для получения списка пользователей
    func fetchUsers(page: Int, completion: @escaping (Result<[UserDetails], APIError>) -> Void) {
        guard let url = URL(string: "https://api.intra.42.fr/v2/users?page=\(page)&per_page=20") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request failed: \(error)")
                completion(.failure(.requestFailed))
                return
            }
            
            guard let data = data else {
                completion(.failure(.requestFailed))
                return
            }
            do {
                let users = try JSONDecoder().decode([UserDetails].self, from: data)
                print("Users: \(users)")
                completion(.success(users))
            } catch {
                print("Decoding failed: \(error)")
                completion(.failure(.decodingFailed))
            }
        }.resume()
    }
}

