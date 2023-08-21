import Foundation
import CloudKit

enum CourtRecordKeys: String {
    case type = "NewCourt"
    case Name
    case Image
    case Description
}

struct Court {
    var id: CKRecord.ID?
    var name: String
    var image: CKAsset? // Assuming the image is stored as a CKAsset
    var description: String?
    var teamWins: [String: Int] = [:] // Dictionary to store team wins
    var teamWithMostWins: String = ""
}

extension Court {
    init?(record: CKRecord) {
        guard let name = record[CourtRecordKeys.Name.rawValue] as? String else {
            return nil
        }
        
        let image = record[CourtRecordKeys.Image.rawValue] as? CKAsset
        let description = record[CourtRecordKeys.Description.rawValue] as? String

        self.init(id: record.recordID, name: name, image: image, description: description)
    }
}

extension Court {
    var record: CKRecord {
        let record = CKRecord(recordType: CourtRecordKeys.type.rawValue)
        record[CourtRecordKeys.Name.rawValue] = name
        record[CourtRecordKeys.Image.rawValue] = image
        record[CourtRecordKeys.Description.rawValue] = description
        return record
    }
}


