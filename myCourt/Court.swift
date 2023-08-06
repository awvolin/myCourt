//
//  Court.swift
//  myCourt
//
//  Created by Alex Volin on 8/5/23.
//

import Foundation
import CloudKit

enum CourtRecordKeys: String {
    case type = "NewCourt"
    case name
}

struct Court {
    var id: CKRecord.ID?
    var name: String
    
}

extension Court {
    init?(record: CKRecord) {
        guard let name = record[CourtRecordKeys.name.rawValue] as? String
                
                
        else {
            return nil
        }
        self.init(id: record.recordID, name: name)
    }
}



extension Court {
    var record: CKRecord {
        let record = CKRecord(recordType: CourtRecordKeys.type.rawValue)
        record[CourtRecordKeys.type.rawValue] = name
        return record
        
    }
}
