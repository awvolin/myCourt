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
import AuthenticationServices

struct ContentView: View {
    @State private var loggedIn = false
    
    var body: some View {
        NavigationView {
            if loggedIn {
                // Show the logged-in view when the user is logged in
                LoggedInView()
            } else {
                // Show the initial splash screen when the user is not logged in
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
                                .frame(height: 140)
                                .padding(25)
                            Button {
                                loggedIn = true
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
        }
    }
}
//
// Main view
//
struct LoggedInView: View {
    @State private var courtName: String = ""
    @StateObject private var model = CourtViewModel()
    @StateObject private var gameViewModel = GameViewModel()
    @State private var selectedCourt: Court?
    
    @State private var showAddCourt = false
    @State private var showAddGame = false
    @State private var scale: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    
    
    var body: some View {
        VStack {
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
                            VStack (alignment: .leading, spacing: 0) {
                                image(from: court.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 120)
                                    .clipped()
                                
                                VStack(alignment: .leading) {
                                    Text(court.name)
                                        .font(.largeTitle.weight(.bold))
                                        .foregroundColor(.black)
                                    if let courtDescription = court.description {
                                        Text(courtDescription)
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                            }
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                            .padding(10)
                            .scaleEffect(scale)
                            .onAppear {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    scale = 1
                                }
                            }
                            .onTapGesture {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    selectedCourt = court
                                    Task {
                                        do {
                                            guard let courtID = court.id else {
                                                return
                                            }
                                            try await gameViewModel.getGames(for: courtID)
                                        } catch {
                                            // Handle error
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
                            // Handle error
                        }
                    }
                }
            } else {
                VStack {
                    image(from: selectedCourt?.image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading) {
                        Text(selectedCourt!.name)
                            .font(.largeTitle.weight(.bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.black)
                        
                        Spacer().frame(height: 10)
                        
                        if let selectedCourtDescription = selectedCourt?.description {
                            Text(selectedCourtDescription)
                                .foregroundColor(.gray)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Orange block with "King of The Court:" and a name
                        ZStack(alignment: .leading) {
                            Color.orange
                                .frame(maxWidth: .infinity)
                                .frame(height: 80) // Adjust the height as needed
                                .cornerRadius(12)
                            HStack {
                                Text("King of The Court:")
                                    .font(.system(size: 20, weight: .bold)) // Replace 20 with the desired font size
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                Text("\(findMostFrequentWinner() ?? "")")
                                    .font(.system(size: 20, weight: .bold)) // Replace 16 with the desired font size
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                            }
                            
                            
                            .padding(.horizontal, 16)
                        }
                        
                        
                        HStack {
                            Text("Games")
                                .font(.largeTitle.bold())
                                .foregroundColor(.black)
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
                        
                        ScrollView {
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
                    NewGameView(associatedCourt: selectedCourt, isAddingGame: true)
                }
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
                .padding(10)
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        scale = 1
                    }
                }
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.height
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    scale = 0
                                    selectedCourt = nil
                                }
                            }
                        }
                )
            }
        }
    }
    
    func findMostFrequentWinner() -> String? {
        var winnerCounts: [String: Int] = [:]
        
        for game in gameViewModel.games {
            if let winner = game.winner, game.CourtRef?.recordID == selectedCourt?.id {
                winnerCounts[winner, default: 0] += 1
            }
        }
        
        if let mostFrequentWinner = winnerCounts.max(by: { $0.value < $1.value })?.key {
            return mostFrequentWinner
        }
        
        return nil // No winner found or no games available
    }
}


struct GameRow: View {
    let game: Game
    
    var body: some View {
        ZStack{
            HStack(spacing: 16) {
                // Team One's Score
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 45)
                Text(game.teamOne ?? "Unknown Team")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(game.teamTwo ?? "Unknown Team")
                    .font(.headline)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.trailing)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 45)
                
            }
            HStack(spacing: 16) {
                Text("\(game.scoreOne ?? 0)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                
                Spacer()
                
                Text("\(game.scoreTwo ?? 0)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50) // stretch across screen
        .background(Color.gray.opacity(0.2)) // background of the box
        .cornerRadius(8) // rounded corners
        .padding(.vertical, 4) // space between boxes
    }
}



struct NewCourtView: View {
    @State private var courtName: String = ""
    @State private var courtDescription: String = ""
    @State private var showingImagePicker: Bool = false
    @State private var selectedUIImage: UIImage? = nil
    @State private var feedbackMessage: String = ""
    @State private var isShowingAlert = false
    var courtImage: Image? {
        if let uiImage = selectedUIImage {
            return Image(uiImage: uiImage)
        }
        return nil
    }

    @ObservedObject var courtVM = CourtViewModel()
    
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
                        return nil
                    }
                }()
                
                let newCourt = Court(name: courtName, image: asset, description: courtDescription)

                                Task {
                                    do {
                                        try await courtVM.addCourt(court: newCourt)
                                        feedbackMessage = "Court added successfully"
                                        isShowingAlert = true
                                        // Optionally, reset fields and UI states after successful addition
                                        courtName = ""
                                        courtDescription = ""
                                        selectedUIImage = nil
                                    } catch {
                                        feedbackMessage = "Error adding court - Sign into iCloud on this device."
                                        isShowingAlert = true
                                    }
                                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("Court Status"), message: Text(feedbackMessage), dismissButton: .default(Text("OK")))
        }
        .background(Color.white)
        .padding()
        .preferredColorScheme(.light)
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
    @State private var feedbackMessage: String = ""
    @State public var isAddingGame: Bool
    @State private var isShowingAlert = false

    
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
                        do {
                                        try await gameViewModel.addGame(game: newGame)
                                        
                                        // Optional: Reset the fields
                                        teamOne = ""
                                        scoreOne = ""
                                        teamTwo = ""
                                        scoreTwo = ""
                                        
                                        // Provide feedback to the user
                                        feedbackMessage = "Game added successfully"
                                        
                                        // Show the alert
                                        isShowingAlert = true
                                        
                                        // Close the new game screen
                                        isAddingGame = false
                                    } catch {
                                        feedbackMessage = "Error adding game  - Sign into iCloud on this device."
                                        
                                        // Show the alert
                                        isShowingAlert = true
                                    }
                                }
                            }
                        }

            
            
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .frame(maxWidth: .infinity, alignment: .center)
        }.preferredColorScheme(.light)
            .background(Color.white)
            .padding()
            .alert(isPresented: $isShowingAlert) {
                        Alert(title: Text("Game Status"), message: Text(feedbackMessage), dismissButton: .default(Text("OK")))
                    }
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
