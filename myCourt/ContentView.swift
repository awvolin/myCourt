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
    @State var vm = ViewModel()
    @State private var loggedIn = false
    
    @State private var selectedLocation: Location?
    
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
    
    @StateObject private var mapAPI = MapAPI()
    @State private var text = ""
    
    @State private var showingPopover = false
    @State private var selectedLocation: Location?
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter an address", text: $text)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            Button("Find address") {
                mapAPI.getLocation(address: text, delta: 0.5)
            }
            
            Button("Log out", action: {
                logOutAction()
                loggedIn = false
            })
            
            //map location points
            let permanentMarker = Location(name: "this", coordinate: CLLocationCoordinate2D(latitude: 39.714802, longitude: -75.116957))
            var allLocations: [Location] {
                return mapAPI.locations + [permanentMarker]
            }
            
            Map(coordinateRegion: $mapAPI.region, annotationItems: allLocations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    Button(action: {
                        selectedLocation = location
                        showingPopover = true
                    }) {
                        Image(systemName: "basketball")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.orange)
                    }
                    .popover(isPresented: $showingPopover, content: {
                        if let location = selectedLocation {
                            PopoverContent(location: location)
                        }
                    })
                }
            }
            .ignoresSafeArea()
        }
    }
}


struct PopoverContent: View {
    let location: Location

    var body: some View {
        VStack {
            Text("Location: \(location.name)")
            // add more content as needed
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }}

