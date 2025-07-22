//
//  UserCache.swift
//  42
//
//  Created by Anton on 06.01.2025.
//

import Foundation

class UserCache: ObservableObject {
    @Published private(set) var cachedUsers: [String: UserDetails] = [:]
    
    func getCachedUser(for login: String) -> UserDetails? {
        cachedUsers[login]
    }
    
    func cacheUser(_ user: UserDetails, for login: String) {
        cachedUsers[login] = user
    }
}

