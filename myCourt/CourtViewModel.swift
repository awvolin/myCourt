import CloudKit
import Foundation

class CourtViewModel: ObservableObject {
    // Reference the specific container 'iCloud.com.volin.dev.myCourt'
    private var db = CKContainer(identifier: "iCloud.com.volin.dev.myCourt").publicCloudDatabase
    @Published private var courtDictionary: [CKRecord.ID: Court] = [:]

    var courts: [Court] {
        courtDictionary.values.compactMap { $0 }
    }

    func addCourt(court: Court) async throws {
        let record = court.record
        let _ = try await db.save(record)
        try await getCourts()
    }

    func getCourts() async throws {
        let query = CKQuery(recordType: CourtRecordKeys.type.rawValue, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: CourtRecordKeys.Name.rawValue, ascending: true)]
        let result = try await db.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }

        DispatchQueue.main.async {
            records.forEach { record in
                self.courtDictionary[record.recordID] = Court(record: record)
            }
        }
    }
}

