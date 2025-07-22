//
//  Users.swift
//  42
//
//  Created by Anton on 16.12.2024.
//

import Foundation

struct UserDetails: Identifiable, Codable, Equatable  {
    let id: Int
    let email: String
    let login: String
    let firstName: String?
    let lastName: String?
    let usualFullName: String?
    let usualFirstName: String?
    let url: String
    let phone: String?
    let displayname: String?
    let image: UserImage?
    let cursus_users: [CursusUser]?
    let campus: [Campus]?
    let projects_users: [ProjectsUser]?
    
    static func ==(lhs: UserDetails, rhs: UserDetails) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ProjectsUser: Codable, Identifiable {
    let id: Int
    let final_mark: Int?
    let project: Project?
}

struct Project: Codable, Identifiable {
    let id: Int
    let name: String
}

struct Skills: Codable, Identifiable {
    let id: Int
    let name: String
    let level: Double
}

struct UserImage: Codable {
    let link: String?
    let versions: ImageVersions?
}

struct ImageVersions: Codable {
    let large: String?
    let medium: String?
    let small: String?
    let micro: String?
}

struct CursusUser: Codable, Identifiable {
    let id: Int
    let level: Double
    let skills: [Skills]?
}

struct Campus: Codable {
    let name: String
}

struct Secrets {
    static var clientID: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path) as? [String: Any],
              let clientID = dictionary["CLIENT_ID"] as? String else {
            return ""
        }
        return clientID
    }

    static var clientSecret: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path) as? [String: Any],
              let clientSecret = dictionary["CLIENT_SECRET"] as? String else {
            return ""
        }
        return clientSecret
    }
}
