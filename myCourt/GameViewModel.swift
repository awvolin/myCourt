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
        query.sortDescriptors = [NSSortDescriptor(key: GameRecordKeys.Date.rawValue, ascending: true)]
        let result = try await db.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }

        DispatchQueue.main.async {
            records.forEach { record in
                self.gameDictionary[record.recordID] = Game(record: record)
            }
        }
    }
}
