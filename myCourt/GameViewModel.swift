import CloudKit
import Foundation

class GameViewModel: ObservableObject {
    // Reference the specific container 'iCloud.com.volin.dev.myCourt'
    private var db = CKContainer(identifier: "iCloud.com.volin.dev.myCourt").publicCloudDatabase
    @Published private var gameDictionary: [CKRecord.ID: Game] = [:]

    var games: [Game] {
        gameDictionary.values.compactMap { $0 }
    }

    func addGame(game: Game) async throws {
        let record = game.record
        let _ = try await db.save(record)
        try await getGames()
    }

    func getGames() async throws {
        let query = CKQuery(recordType: GameRecordKeys.type.rawValue, predicate: NSPredicate(value: true))

        let result = try await db.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }

        DispatchQueue.main.async {
            self.gameDictionary = [:]  // Clear previous games
            
            records.forEach { record in
                if let game = Game(record: record) {
                    self.gameDictionary[record.recordID] = game
                }
            }
        }
    }



    func getGames(for courtID: CKRecord.ID) async throws {
        let predicate = NSPredicate(format: "%K == %@", GameRecordKeys.CourtRef.rawValue, CKRecord.Reference(recordID: courtID, action: .deleteSelf))
        let query = CKQuery(recordType: GameRecordKeys.type.rawValue, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: GameRecordKeys.Date.rawValue, ascending: true)]
        let result = try await db.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }

        DispatchQueue.main.async {
            self.gameDictionary = [:]  // Clear previous games
            records.forEach { record in
                self.gameDictionary[record.recordID] = Game(record: record)
            }
            print("getGames(for:): Fetched \(self.gameDictionary.count) games for court ID \(courtID.recordName)") // Debug print
        }
    }
    
    
    //debugging function 
    func checkGames() async {
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: GameRecordKeys.type.rawValue, predicate: predicate)
            do {
                let result = try await db.records(matching: query)
                let records = result.matchResults.compactMap { try? $0.1.get() }

                DispatchQueue.main.async {
                    print("checkGames(): Fetched \(records.count) games")
                    for record in records {
                        print("Game record ID: \(record.recordID.recordName)")
                        if let courtRef = record[GameRecordKeys.CourtRef.rawValue] as? CKRecord.Reference {
                            print("  Court reference ID: \(courtRef.recordID.recordName)")
                        }
                        if let date = record[GameRecordKeys.Date.rawValue] as? Date {
                            let formatter = DateFormatter()
                            formatter.dateStyle = .medium
                            formatter.timeStyle = .medium
                            print("  Game date: \(formatter.string(from: date))")
                        }
                        print("---")
                    }
                }
            } catch {
                print("An error occurred while fetching games: \(error)")
            }
        }
}
