//
//  ProfileView.swift
//  BOOK
//
//  Created by IOSLAB on 14/11/2024.
//

import SwiftUI

struct ProfileView: View {
    
    var body: some View {
        
        NavigationView {
            VStack {
                Spacer() // Pushes buttons to the bottom
                
                HStack {
                   /*NavigationLink(destination: BookView()) {
                        Image("BookIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                    .padding()*/
                    
                    NavigationLink(destination: BookListView()) {
                        Image("BookIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                    .padding()
                    
                    NavigationLink(destination: GoalsView()) {
                        Image("ListIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                    .padding()
                    
                    NavigationLink(destination: ProfileView()) {
                        Image("ProfileIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                    .padding()
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview{
    ProfileView()
}
