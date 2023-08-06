import CloudKit

class CourtViewModel: ObservableObject {
    @Published var courts: [Court] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private var container = CKContainer(identifier: "iCloud.com.volin.dev.myCourt")
    private var publicDatabase: CKDatabase {
        return container.publicCloudDatabase
    }

    
    func fetchCourts() {
        isLoading = true

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "court", predicate: predicate)

        publicDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: ["name", "description", "numGames"], resultsLimit: Int.max) { [weak self] (result: Result<(matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?), Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    // Debug print statement for records received
                    if data.matchResults.isEmpty {
                        print("No records received.")
                    } else {
                        print("Received \(data.matchResults.count) records.")
                        for (id, recordResult) in data.matchResults {
                            switch recordResult {
                            case .success(let record):
                                print("Record ID: \(id), Name: \(String(describing: record["name"])), Description: \(String(describing: record["description"])), NumGames: \(String(describing: record["numGames"]))")
                            case .failure(let error):
                                print("Error fetching record with ID \(id): \(error)")
                            }
                        }
                    }

                    self?.courts = data.matchResults.compactMap { (_, recordResult) -> Court? in
                        switch recordResult {
                        case .success(let record):
                            guard let courtName = record["name"] as? String,
                                  let description = record["description"] as? String,
                                  let numGames = record["numGames"] as? Int64 else { return nil }
                            return Court(id: record.recordID.recordName, name: courtName, description: description, numGames: numGames)
                        case .failure:
                            return nil
                        }
                    }
                case .failure(let error):
                    // Debug print statement for errors
                    print("Error fetching courts: \(error)")
                    self?.error = error
                }
                self?.isLoading = false
            }
        }
    }
}



//  HARDCODE

//
//import CloudKit
//
//class CourtViewModel: ObservableObject {
//    @Published var courts: [Court] = []
//
//  private var publicDatabase = CKContainer.default().publicCloudDatabase
//  let container = CKContainer(identifier: "iCloud.com.volin.dev.myCourt")
//    init() {
//        // Manually generating sample courts
//        courts = [
//            Court(name: "Rowan Rec Center", description: "Main rec center court at Rowan", numGames: 5),
//            Court(name: "Rowan Cages", description: "Cage courts near the dorms", numGames: 2),
//            Court(name: "Williamsburg Court", description: "Open court in Williamsburg", numGames: 3),
//            Court(name: "City Square Court", description: "Downtown city square court", numGames: 4),
//            Court(name: "Riverside Court", description: "Quiet court by the riverside", numGames: 1),
//            Court(name: "Green Park Court", description: "Court in the middle of Green Park", numGames: 3)
//        ]
//    }
//}

