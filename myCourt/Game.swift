import Foundation
import CloudKit

enum GameRecordKeys: String {
    case type = "Game"
    case Name
    case TeamOne
    case TeamTwo
    case ScoreOne
    case ScoreTwo
    case Date
}

struct Game {
    var id: CKRecord.ID?
    var name: String
    var teamOne: String?
    var teamTwo: String?
    var scoreOne: Int64?
    var scoreTwo: Int64?
}

extension Game {
    init?(record: CKRecord) {
        guard let name = record[GameRecordKeys.Name.rawValue] as? String else {
            return nil
        }
        let teamOne = record[GameRecordKeys.TeamOne.rawValue] as? String
        let teamTwo = record[GameRecordKeys.TeamTwo.rawValue] as? String
        let scoreOne = record[GameRecordKeys.ScoreOne.rawValue] as? Int64
        let scoreTwo = record[GameRecordKeys.ScoreTwo.rawValue] as? Int64

        self.init(id: record.recordID, name: name, teamOne: teamOne, teamTwo: teamTwo, scoreOne: scoreOne, scoreTwo: scoreTwo)
    }
}

extension Game {
    var record: CKRecord {
        let record = CKRecord(recordType: CourtRecordKeys.type.rawValue)
        record[GameRecordKeys.Name.rawValue] = name
        record[GameRecordKeys.ScoreOne.rawValue] = scoreOne
        record[GameRecordKeys.ScoreTwo.rawValue] = scoreTwo
        record[GameRecordKeys.TeamTwo.rawValue] = teamTwo
        record[GameRecordKeys.TeamTwo.rawValue] = teamTwo
        return record
    }
}


