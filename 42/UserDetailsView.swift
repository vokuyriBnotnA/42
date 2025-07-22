//
//  UserDetails.swift
//  42
//
//  Created by Anton on 30.12.2024.
//
//
import SwiftUI

struct UserDetailsView: View {
    @EnvironmentObject var userCache: UserCache
    let login: String
    let accessToken: String
    let logout: () -> Void
    
    @State private var user: UserDetails? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ScrollView {
            Group {
                if let user = user {
                    userDetailsView(user: user)
                } else if isLoading {
                    ProgressView("Loading...")
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                    Button(action: logout) {
                        Text("Exit")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    
                }
            }
        }
        .navigationTitle("User Profile")
        .onAppear(perform: handleLoad)
    }
    
    private func userDetailsView(user: UserDetails) -> some View {
        VStack(spacing: 16) {
            
            AsyncImage(url: URL(string: user.image?.link ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 120, height: 120)
                case .failure:
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(user.login)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(user.displayname ?? "unknown")")
                    .font(.title2)
                    .fontWeight(.bold)
                
                ForEach(user.cursus_users ?? [], id: \.id) { cursusUser in
                    Text("\(String(format: "%.1f", cursusUser.level)) lvl")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Text("\(user.email)")
                    .font(.subheadline)
                
                if let campuses = user.campus {
                    let campusNames = campuses.map { $0.name }.joined(separator: ", ")
                    Text(campusNames)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Skills")
                    .font(.title2)
                    .fontWeight(.semibold)
                if let cursusUsers = user.cursus_users, !cursusUsers.isEmpty {
                    ForEach(cursusUsers) { cursusUser in
                        VStack(alignment: .leading, spacing: 8) {
                            
                            if cursusUser.skills != nil {
                                ForEach(cursusUser.skills!) { skill in
                                    HStack {
                                        Text(skill.name)
                                            .font(.body)
                                        Spacer()
                                        Text("\(String(format: "%.1f", skill.level)) (\(String(format: "%.0f", skill.level / 20 * 100))%)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                    
                } else {
                    Text("No skills")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Divider()
            
            if user.projects_users != nil {
                NavigationLink(destination: ProjectsListView(projectsUsers: user.projects_users!)) {
                    Text("View Projects")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            if login == "me" {
                Button(action: logout) {
                    Text("Exit")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
    
    private func handleLoad() {
        if let cachedUser = userCache.getCachedUser(for: login) {
            user = cachedUser
        } else {
            loadUserProfile()
        }
    }
    
    private func loadUserProfile() {
        isLoading = true
        Task {
            do {
                let userDetails = try await fetchUserProfile(login: login)
                DispatchQueue.main.async {
                    self.user = userDetails
                    self.userCache.cacheUser(userDetails, for: login)
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchUserProfile(login: String) async throws -> UserDetails {
        guard let url = URL(string: "https://api.intra.42.fr/v2/\(login)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(UserDetails.self, from: data)
    }
}
