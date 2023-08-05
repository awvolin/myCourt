import CloudKit
import Combine

//class CourtViewModel: ObservableObject {
//    @Published var courts: [Court] = []
//    @Published var isLoading: Bool = false
//    @Published var error: Error?
//
//    private var container: CKContainer
//    private var publicDatabase: CKDatabase
//
//    init() {
//        self.container = CKContainer.default()
//        self.publicDatabase = container.publicCloudDatabase
//    }
//
//    func fetchCourts() {
//        isLoading = true
//
//        let predicate = NSPredicate(value: true)
//        let query = CKQuery(recordType: "court", predicate: predicate)
//
//        publicDatabase.perform(query, inZoneWith: nil) { [weak self] (results, err) in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//
//                if let error = err {
//                    print("Error fetching records: \(error)")
//                    self?.error = error
//                    return
//                }
//
//                guard let results = results else { return }
//
//                self?.courts = results.map { record -> Court in
//                    let courtName = record["name"] as? String ?? "No name"
//                    return Court(id: record.recordID.recordName, name: courtName)
//                }
//            }
//        }
//    }
//}
class CourtViewModel: ObservableObject {
    @Published var courts: [Court] = []

    init() {
        // Manually generating sample courts
        courts = [
            Court(name: "Rowan Rec Center"),
            Court(name: "Rowan Cages"),
            Court(name: "Williamsburg Court"),
            Court(name: "City Square Court"),
            Court(name: "Riverside Court"),
            Court(name: "Green Park Court")
        ]
    }
}
