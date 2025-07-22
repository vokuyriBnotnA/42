//
//  UserProfileView.swift
//  42
//
//  Created by Anton on 14.12.2024.
//

import SwiftUI

struct UserProfileView: View {
    let accessToken: String
    @ObservedObject var authViewModel: AuthViewModel
    @State private var userInfo: [String: Any]?
    
    @State private var users: [UserDetails] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchQuery = ""
    @State private var page = 1
    
    @EnvironmentObject var userCache: UserCache

    
    var body: some View {
        TabView {
            NavigationView {
                UsersListView(isLoading: $isLoading, users: $users, errorMessage: $errorMessage, accessToken: accessToken) .environmentObject(userCache)
            }
            .tabItem {
                Label("Search", systemImage: "loupe")
            }
            NavigationView {
                UserDetailsView(login: "me", accessToken: accessToken, logout: authViewModel.logout) .environmentObject(userCache)
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
    }
    

}
