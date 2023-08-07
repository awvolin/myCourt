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
import CloudKit

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
    @StateObject private var gameViewModel = GameViewModel()    
    @Namespace var namespace
    @State private var selectedCourt: Court?
    
    var body: some View {
       
        //Cards shown up to "else"
        
        if selectedCourt == nil {
            VStack(spacing: 20) {
                TextField("Enter Court", text: $courtName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
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
                        VStack (alignment: .leading, spacing: 12) {
                            image(from: court.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                                .matchedGeometryEffect(id: "image\(String(describing: court.id))", in: namespace)
                            
                            VStack(alignment: .leading) {
                                Text(court.name)
                                    .font(.largeTitle.weight(.bold))
                                    .matchedGeometryEffect(id: "title\(String(describing: court.id))", in: namespace)
                                
                                if let courtDescription = court.description {
                                    Text(courtDescription)
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                        .matchedGeometryEffect(id: "subtitle\(String(describing: court.id))", in: namespace)
                                }
                            }
                            .padding()
                        }
                        .background(Color.white
                            .matchedGeometryEffect(id: "background\(String(describing: court.id))", in: namespace))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                        .padding(10)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedCourt = court
                                Task {
                                    do {
                                        try await gameViewModel.getGames()
                                    } catch {
                                        print("Error fetching games for court \(court.id!): \(error)")
                                    }
                                }
                            }
                        }
                    }
                }
                
                Button("Log out", action: {
                    logOutAction()
                    loggedIn = false
                })
            }
            .onAppear {
                            Task {
                                do {
                                    try await model.getCourts()
                                    try await gameViewModel.getGames()
                                } catch {
                                    print("Error fetching courts: \(error)")
                                }
                            }
                        }
            
            //  Showing information on one court
            
        } else {
            VStack {
                image(from: selectedCourt?.image)
                    .resizable()
                    .scaledToFit() // Adjust to fit the width and retain original aspect ratio
                    .frame(maxWidth: .infinity) // Ensure it stretches across the width of the device
                    .matchedGeometryEffect(id: "image\(String(describing: selectedCourt!.id))", in: namespace)

                VStack(alignment: .leading) {
                    Text(selectedCourt!.name)
                        .font(.largeTitle.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .matchedGeometryEffect(id: "title\(String(describing: selectedCourt!.id))", in: namespace)
                    
                    if let selectedCourtDescription = selectedCourt?.description {
                        Text(selectedCourtDescription)
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(1)
                            .matchedGeometryEffect(id: "subtitle\(String(describing: selectedCourt!.id))", in: namespace)
                    }
                    Text("Previous Games")
                        .font(.largeTitle.bold())
                    List(gameViewModel.games) { game in
                        if let teamOne = game.teamOne {
                            Text(teamOne)
                        }
                    }
                }
                .padding()
                
                Spacer() 
            }
            .background(Color.white
                .matchedGeometryEffect(id: "background\(String(describing: selectedCourt!.id))", in: namespace)
            )
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
            .padding(10)
            .onTapGesture {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    selectedCourt = nil
                }
            }

        }
    }
    
}

//  Helper for image asset conversion

func image(from asset: CKAsset?) -> Image {
    guard let asset = asset, let data = try? Data(contentsOf: asset.fileURL!), let uiImage = UIImage(data: data) else {
        return Image("defaultImageName") // Replace with your placeholder image name if the CKAsset is nil or invalid
    }
    return Image(uiImage: uiImage)
}

// Preview Logic

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }}
