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
    
    @State private var showAddCourt = false
    @State private var showAddGame = false
    
    var body: some View {
        
        //Cards shown up to "else"
        
        if selectedCourt == nil {
            VStack(spacing: 20) {
                HStack {
                    Text("My Courts")
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                    
                    Button(action: {
                        showAddCourt.toggle()
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding(15)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                
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
                                        guard let courtID = court.id else {
                                            print("Error: Court ID is missing!")
                                            return
                                        }
                                        try await gameViewModel.getGames(for: courtID)
                                    } catch {
                                        print("Error fetching games for court \(court.id!): \(error)")
                                    }
                                }
                            }
                        }
                        
                    }
                }
            }
            .sheet(isPresented: $showAddCourt) {
                NewCourtView()
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
                    Spacer()
                        .frame(height: 10)
                    if let selectedCourtDescription = selectedCourt?.description {
                        Text(selectedCourtDescription)
                            .foregroundColor(.gray)
                            .lineLimit(nil)  // Remove line limit
                            .fixedSize(horizontal: false, vertical: true)
                            .matchedGeometryEffect(id: "subtitle\(String(describing: selectedCourt!.id))", in: namespace)
                    }
                    HStack {
                        Text("Games")
                            .font(.largeTitle.bold())
                        Spacer()
                        Button(action: {
                            showAddGame.toggle()
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                    
                    LazyVStack {
                        ForEach(gameViewModel.games) { game in
                            GameRow(game: game)
                        }
                    }
                    .padding(.top)
                }
                .padding()
                
                Spacer()
            }
            .sheet(isPresented: $showAddGame) {
                NewGameView(associatedCourt: selectedCourt)
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

struct GameRow: View {
    let game: Game
    
    var body: some View {
        HStack(spacing: 16) {
            // Team One's Name
            Text(game.teamOne ?? "Unknown Team")
                .font(.headline)
                .foregroundColor(.blue)
            
            Spacer() // pushes text apart
            
            // Scores with a dash between them
            VStack {
                Text(scoreRepresentation)
                    .font(.title2)
                    .foregroundColor(.black)
            }
            
            Spacer() // pushes text apart
            
            // Team Two's Name
            Text(game.teamTwo ?? "Unknown Team")
                .font(.headline)
                .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity, minHeight: 50) // stretch across screen
        .background(Color.gray.opacity(0.2)) // background of the box
        .cornerRadius(8) // rounded corners
        .padding(.vertical, 4) // space between boxes
    }
    
    var scoreRepresentation: String {
        let scoreOne = game.scoreOne ?? 0
        let scoreTwo = game.scoreTwo ?? 0
        return "\(scoreOne) - \(scoreTwo)"
    }
}

struct NewCourtView: View {
    @State private var courtName: String = ""
    @State private var courtDescription: String = ""
    @State private var showingImagePicker: Bool = false
    @State private var selectedUIImage: UIImage? = nil
    var courtImage: Image? {
        if let uiImage = selectedUIImage {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Court")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Court Name")
                        .font(.headline)
                    TextField("Enter court name...", text: $courtName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    Text("Description")
                        .font(.headline)
                    TextField("Enter court description...", text: $courtDescription)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button("Select Image") {
                    showingImagePicker.toggle()
                }
                
                if let courtImage = courtImage {
                    courtImage
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            @ObservedObject var courtVM = CourtViewModel()

            Button("Add Court") {
                // Convert UIImage to CKAsset
                let asset: CKAsset? = {
                    guard let image = selectedUIImage else { return nil }
                    let data = image.jpegData(compressionQuality: 0.7)
                    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("jpeg")
                    do {
                        try data?.write(to: tempURL)
                        return CKAsset(fileURL: tempURL)
                    } catch {
                        print("Error saving image to temporary directory: \(error)")
                        return nil
                    }
                }()

                let newCourt = Court(name: courtName, image: asset, description: courtDescription)
                
                Task {
                    do {
                        try await courtVM.addCourt(court: newCourt)
                        // Optionally, reset fields and UI states after successful addition
                        courtName = ""
                        courtDescription = ""
                        selectedUIImage = nil
                    } catch {
                        print("Error adding new court: \(error)")
                        // Handle the error, possibly with an alert to the user.
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .frame(maxWidth: .infinity, alignment: .center)

            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color.white)
        .padding()
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(isPresented: $showingImagePicker, selectedImage: $selectedUIImage)
        }
    }
}

struct NewGameView: View {
    var associatedCourt: Court?
    @State private var gameDate = Date()
    @State private var teamOne: String = ""
    @State private var scoreOne: String = ""
    @State private var teamTwo: String = ""
    @State private var scoreTwo: String = ""
    
    @ObservedObject var gameViewModel = GameViewModel()

    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Game")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            VStack(spacing: 20) {
                DatePicker("Game Date", selection: $gameDate, displayedComponents: .date)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Team")
                            .font(.headline)
                        TextField("Team One", text: $teamOne)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Score")
                            .font(.headline)
                        TextField("Score One", text: $scoreOne)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .keyboardType(.numberPad)  // Only numbers for score input
                    }
                }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Team")
                            .font(.headline)
                        TextField("Team Two", text: $teamTwo)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Score")
                            .font(.headline)
                        TextField("Score Two", text: $scoreTwo)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .keyboardType(.numberPad)  // Only numbers for score input
                    }
                }
                
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button("Add Game") {
                Task {
                    do {
                        guard let scoreOneInt = Int64(scoreOne), let scoreTwoInt = Int64(scoreTwo) else {
                            print("Invalid scores entered!")
                            return
                        }

                        // Simplified court reference creation
                        let courtReference = associatedCourt?.id.map { CKRecord.Reference(recordID: $0, action: .none) }

                        // Create the game object with the simplified court reference
                        let newGame = Game(teamOne: teamOne,
                                           teamTwo: teamTwo,
                                           scoreOne: scoreOneInt,
                                           scoreTwo: scoreTwoInt,
                                           date: gameDate,
                                           CourtRef: courtReference)

                        // Save the game to the database
                        try await gameViewModel.addGame(game: newGame)

                        // Optional: Reset the fields
                        teamOne = ""
                        scoreOne = ""
                        teamTwo = ""
                        scoreTwo = ""

                        print("Game added successfully!")
                    } catch {
                        print("Failed to add game: \(error)")
                    }
                }
            }


            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color.white)
        .padding()
    }
}



struct ImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> some UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = uiImage
            }
            
            parent.isPresented = false
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
