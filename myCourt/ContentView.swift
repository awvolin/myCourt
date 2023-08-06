//
//  ContentView.swift
//  myCourt
//
//  Created by Alex Volin on 6/21/23.
//  Map Version deprecated on 7/27/23
//

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @State private var showingLoginView = false
    @State var vm = LoginViewModel()
    @State private var loggedIn = false
    
    
    var body: some View {
        NavigationStack {
            
            //Initial splashscreen
            if(!showingLoginView) {
                GeometryReader{ geo in
                    ZStack (alignment: .top) {
                        Image("Wallpaper")
                            .resizable()
                            .aspectRatio(geo.size, contentMode: .fill)
                            .edgesIgnoringSafeArea(.all)
                        VStack {
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame( height: 140)
                                .foregroundColor(Color.white)
                                .padding(25)
                            Button {
                                showingLoginView = true
                            } label: {
                                Text("I got next.")
                            }
                            .padding(10)
                            .background(.orange)
                            .foregroundColor(.black)
                            .font(.headline)
                            .cornerRadius(10)
                        }
                    }
                }
            }
            else {
                
                //Login Page
                if !loggedIn {
                    GeometryReader{ geo in
                        ZStack (alignment: .top) {
                            Color(hue: 0, saturation: 0, brightness: 0.77)
                                .aspectRatio(geo.size, contentMode: .fill)
                                .edgesIgnoringSafeArea(.all)
                            
                            VStack {
                                Image("logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame( height: 140)
                                    .foregroundColor(Color.white)
                                    .padding(25)
                                TextField("Username", text: $vm.username)
                                    .textFieldStyle(.roundedBorder)
                                    .textInputAutocapitalization(.never)
                                SecureField("Password", text: $vm.password)
                                    .textFieldStyle(.roundedBorder)
                                    .textInputAutocapitalization(.never)
                                    .privacySensitive()
                                HStack {
                                    Spacer()
                                    Button("Forgot password?", action: vm.logPressed)
                                    Spacer()
                                    Button("Log in", action: {
                                        vm.authenticate()
                                        if(vm.authenticated) {
                                            loggedIn.toggle()
                                        }
                                    })
                                    Spacer()
                                }
                                
                            }
                            
                        }
                    }
                    
                }
                
                //Logged in - launch loggedInView
                else {
                    LoggedInView(loggedIn: $loggedIn, username: vm.username, logOutAction: vm.logOut)
                }
                
            }
        }
    }
}

//
// Main view
//

struct LoggedInView: View {
    @Binding var loggedIn: Bool
    var username: String
    var logOutAction: () -> Void

    @State private var courtName: String = ""
    @StateObject private var model = CourtViewModel()
    @Namespace var namespace
    @State private var selectedCourt: Court?

    var body: some View {
        ZStack {
            // Main view when not showing court details
            if selectedCourt == nil {
                GeometryReader { geo in
                    Color(hue: 0, saturation: 0, brightness: 0.77)
                        .aspectRatio(geo.size, contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 20) {
                        TextField("Enter Court", text: $courtName)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                Task {
                                    do {
                                        let court = Court(name: courtName)
                                        try await model.addCourt(court: court)
                                    } catch {
                                        print("Failed to add court: \(error)")
                                    }
                                }
                            }

                        ScrollView {
                            ForEach(model.courts, id: \.id) { court in
                                Text(court.name)
                                    .font(.largeTitle.weight(.bold))
                                    .matchedGeometryEffect(id: "title\(court.id)", in: namespace)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(20)
                                    .foregroundStyle(.white)
                                    .background(
                                        Color.orange
                                            .matchedGeometryEffect(id: "background\(court.id)", in: namespace)
                                    )
                                    .padding()
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            selectedCourt = court
                                        }
                                    }
                            }
                        }

                        Button("Log out", action: {
                            logOutAction()
                            loggedIn = false
                        })
                    }
                    .padding()
                }
            } else {
                // Detail view for a selected court
                VStack {
                    Text(selectedCourt!.name)
                        .font(.largeTitle.weight(.bold))
                        .matchedGeometryEffect(id: "title\(selectedCourt!.id)", in: namespace)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .foregroundStyle(.white)
                        .background(
                            Color.orange.matchedGeometryEffect(id: "background\(selectedCourt!.id)", in: namespace)
                        )
                        .padding()
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        selectedCourt = nil
                    }
                }
            }
        }
        .onAppear {
            Task {
                do {
                    try await model.getCourts()
                }
                catch {
                    print("Error fetching courts: \(error)")
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }}
