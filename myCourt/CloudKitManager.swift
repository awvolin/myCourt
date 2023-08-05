//
//  CloudKitManager.swift
//  myCourt
//
//  Created by Alex Volin on 8/5/23.
//

import Foundation
import CloudKit

class CloudKitManager {
    static let shared = CloudKitManager() // Singleton instance
    
    private let container = CKContainer.default()
    private var publicDatabase: CKDatabase {
        return container.publicCloudDatabase
    }

    func fetchCourts(completion: @escaping ([Court]) -> Void) {
        let predicate = NSPredicate(value: true) // Fetch all records
        let query = CKQuery(recordType: "Court", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil) { results, error in
            if let error = error {
                print("Error fetching data from CloudKit: \(error)")
                completion([])
                return
            }

            guard let results = results else {
                completion([])
                return
            }
            
            let courts = results.compactMap { record -> Court? in
                guard let name = record["name"] as? String else {
                    return nil
                }
                return Court(id: record.recordID.recordName, name: name)
            }
            completion(courts)
        }
    }
}
