//
//  ProjectsListView.swift
//  42
//
//  Created by Anton on 06.01.2025.
//

import SwiftUI

struct ProjectsListView: View {
    let projectsUsers: [ProjectsUser]

    var body: some View {
        List(projectsUsers) { projectUser in
            ProjectRow(projectUser: projectUser)
        }
        .navigationTitle("Projects")
    }
}

struct ProjectRow: View {
    let projectUser: ProjectsUser

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let project = projectUser.project {
                Text(project.name)
                    .font(.headline)

                if let finalMark = projectUser.final_mark {
                    Text("Final Mark: \(finalMark)")
                        .font(.subheadline)
                        .foregroundColor(finalMark >= 50 ? .green : .red)
                } else {
                    Text("No final mark")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
