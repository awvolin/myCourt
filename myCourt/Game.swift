import Foundation
import CloudKit

enum GameRecordKeys: String {
    case type = "Game"
    case TeamOne
    case TeamTwo
    case ScoreOne
    case ScoreTwo
    case Date
    case CourtRef
}

struct Game: Identifiable {
    var id: CKRecord.ID?
    var teamOne: String?
    var teamTwo: String?
    var scoreOne: Int64?
    var scoreTwo: Int64?
    var date: Date
    var CourtRef: CKRecord.Reference?

    // Computed property to determine the winner based on scores
        var winner: String? {
            guard let teamOne = teamOne, let teamTwo = teamTwo, let scoreOne = scoreOne, let scoreTwo = scoreTwo else {
                return nil
            }
            
            if scoreOne > scoreTwo {
                return teamOne
            } else if scoreTwo > scoreOne {
                return teamTwo
            } else {
                return nil // It's a tie
            }
        }
}

extension Game {
    init?(record: CKRecord) {
        let teamOne = record[GameRecordKeys.TeamOne.rawValue] as? String
        let teamTwo = record[GameRecordKeys.TeamTwo.rawValue] as? String
        let scoreOne = record[GameRecordKeys.ScoreOne.rawValue] as? Int64
        let scoreTwo = record[GameRecordKeys.ScoreTwo.rawValue] as? Int64
        guard let date = record[GameRecordKeys.Date.rawValue] as? Date else { return nil }
        
        let CourtRef = record[GameRecordKeys.CourtRef.rawValue] as? CKRecord.Reference


        self.init(id: record.recordID, teamOne: teamOne, teamTwo: teamTwo, scoreOne: scoreOne, scoreTwo: scoreTwo, date: date, CourtRef: CourtRef)

    }
}

extension Game {
    var record: CKRecord {
        let record = CKRecord(recordType: GameRecordKeys.type.rawValue)
        record[GameRecordKeys.TeamOne.rawValue] = teamOne as? CKRecordValue
        record[GameRecordKeys.TeamTwo.rawValue] = teamTwo as? CKRecordValue
        record[GameRecordKeys.ScoreOne.rawValue] = scoreOne as? CKRecordValue
        record[GameRecordKeys.ScoreTwo.rawValue] = scoreTwo as? CKRecordValue
        record[GameRecordKeys.Date.rawValue] = date as CKRecordValue
        if let courtReference = CourtRef {
            record[GameRecordKeys.CourtRef.rawValue] = courtReference
        }

        return record
    }
}
