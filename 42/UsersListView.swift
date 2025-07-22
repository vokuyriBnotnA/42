//
//  UsersList.swift
//  42
//
//  Created by Anton on 31.12.2024.
//

import SwiftUI

struct UsersListView: View {
    @Binding var isLoading: Bool
    @Binding var users: [UserDetails]
    @Binding var errorMessage: String?
    var accessToken: String
    @State private var page = 1
    @State private var searchText = ""
    @State private var searchResults: [UserDetails] = []
    
    @EnvironmentObject var userCache: UserCache
    
    var body: some View {
        VStack {
            
            TextField("Enter login", text: $searchText, onCommit: {
                searchUsers()
            })
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if isLoading && users.isEmpty {
                ProgressView("Loading...")
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                List {
                    
                    if !searchResults.isEmpty {
                        ForEach(searchResults) { user in
                            NavigationLink(destination: UserDetailsView(
                                login: "/users/\(user.login)",
                                accessToken: accessToken,
                                logout: { print("Logout tapped") }
                            )) {
                                UserRow(user: user)
                            }
                        } .environmentObject(userCache)
                    } else {
                        
                        ForEach(users) { user in
                            NavigationLink(destination: UserDetailsView(
                                login: "/users/\(user.login)",
                                accessToken: accessToken,
                                logout: { print("Logout tapped") }
                            )) {
                                UserRow(user: user)
                            }
                            .onAppear {
                                if user == users.last {
                                    loadMoreUsers()
                                }
                            }
                        }
                    }
                    
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Users")
        .onAppear {
            if users.isEmpty {
                fetchUsers(page: page)
            }
        }
    }
    
    private func loadMoreUsers() {
        guard !isLoading else { return }
        page += 1
        fetchUsers(page: page)
    }
    
    private func fetchUsers(page: Int) {
        isLoading = true
        let apiService = APIService(accessToken: accessToken)
        apiService.fetchUsers(page: page) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let newUsers):
                    self.users.append(contentsOf: newUsers)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        let apiService = APIService(accessToken: accessToken)
        apiService.searchUsers(query: searchText.lowercased(), page: 1) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let users):
                    searchResults = users
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct UserRow: View {
    let user: UserDetails
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: user.image?.versions?.small ?? "")) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 40, height: 40)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .clipped()
                case .failure:
                    Circle()
                        .fill(Color.red)
                        .frame(width: 40, height: 40)
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(alignment: .leading) {
                Text(user.displayname ?? "")
                    .font(.headline)
                Text(user.login)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}
