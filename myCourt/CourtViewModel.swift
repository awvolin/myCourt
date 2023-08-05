import CloudKit

class CourtViewModel: ObservableObject {
    @Published var courts: [Court] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private var publicDatabase = CKContainer.default().publicCloudDatabase

    func fetchCourts() {
        isLoading = true

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "court", predicate: predicate)

        publicDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: ["name", "description", "numGames"], resultsLimit: Int.max) { [weak self] (result: Result<(matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?), Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
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
                    self?.error = error
                }
                self?.isLoading = false
            }
        }
    }
}
