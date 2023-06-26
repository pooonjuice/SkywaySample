//
//  FirestoreManager.swift
//  SkywaySample
//
//  Created by Ryo Tabuchi on 2023/06/24.
//

import Foundation
import FirebaseFirestore
import SwiftyJSON

struct FirestoreManager {
    private let db = Firestore.firestore()
    
    func rooms() async throws -> [SSRoom] {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("rooms").getDocuments() { (snapshot, error) in
                if let snapshot {
                    let rooms = snapshot.documents.compactMap { document in
                        SSRoom(json: JSON(document.data()))
                    }
                    continuation.resume(with: .success(rooms))
                } else {
                    continuation.resume(with: .success([]))
                }
            }
        }
    }
    
    func createRoom(room: SSRoom) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let parameters: [String: Any] = {
                if let password = room.password {
                    return [
                        "id": room.id,
                        "name": room.name,
                        "password": password
                    ]
                } else {
                    return [
                        "id": room.id,
                        "name": room.name
                    ]
                }
            }()
            db.collection("rooms").addDocument(data: parameters) { _ in
                continuation.resume()
            }
        }
    }
}
