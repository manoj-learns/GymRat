import Foundation

// MARK: - Firestore REST helpers
private struct FSDocument: Codable {
    var fields: [String: FSValue]
    var name: String?
}

private struct FSQueryResponse: Codable {
    var document: FSDocument?
}

private enum FSValue: Codable {
    case string(String)
    case integer(String)   // Firestore encodes integers as strings
    case double(Double)
    case boolean(Bool)

    enum CodingKeys: String, CodingKey {
        case stringValue, integerValue, doubleValue, booleanValue
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try? c.decode(String.self, forKey: .stringValue)  { self = .string(v);  return }
        if let v = try? c.decode(String.self, forKey: .integerValue) { self = .integer(v); return }
        if let v = try? c.decode(Double.self, forKey: .doubleValue)  { self = .double(v);  return }
        if let v = try? c.decode(Bool.self,   forKey: .booleanValue) { self = .boolean(v); return }
        self = .string("")
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string(let v):  try c.encode(v, forKey: .stringValue)
        case .integer(let v): try c.encode(v, forKey: .integerValue)
        case .double(let v):  try c.encode(v, forKey: .doubleValue)
        case .boolean(let v): try c.encode(v, forKey: .booleanValue)
        }
    }

    var stringVal:  String { if case .string(let v)  = self { return v  }; return "" }
    var intVal:     Int    { if case .integer(let v) = self { return Int(v) ?? 0 }; return 0 }
    var doubleVal:  Double { if case .double(let v)  = self { return v  }; return 0 }
}

// MARK: - Firebase Service
actor FirebaseService {
    static let shared = FirebaseService()
    private init() {}

    private var projectId: String {
        UserDefaults.standard.string(forKey: "firebase_project_id") ?? ""
    }

    private var baseURL: String {
        "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents"
    }

    var isConfigured: Bool { !projectId.isEmpty }

    // MARK: - User Profile
    func createOrUpdateUser(userId: String, displayName: String, username: String, avatarIndex: Int) async throws {
        let fields: [String: FSValue] = [
            "userId":      .string(userId),
            "displayName": .string(displayName),
            "username":    .string(username.lowercased()),
            "avatarIndex": .integer(String(avatarIndex))
        ]
        try await patchDocument(collection: "users", docId: userId, fields: fields)
    }

    func searchUser(username: String) async throws -> (userId: String, displayName: String, username: String, avatarIndex: Int)? {
        let results = try await runQuery(collectionId: "users", field: "username", op: "EQUAL", value: .string(username.lowercased()))
        guard let doc = results.first, let fields = doc.fields as [String: FSValue]? else { return nil }
        return (
            userId:      fields["userId"]?.stringVal ?? "",
            displayName: fields["displayName"]?.stringVal ?? "",
            username:    fields["username"]?.stringVal ?? "",
            avatarIndex: fields["avatarIndex"]?.intVal ?? 0
        )
    }

    // MARK: - Weekly Leaderboard
    func submitWeeklyStats(userId: String, displayName: String, username: String,
                           avatarIndex: Int, volume: Double, workouts: Int, calories: Double) async throws {
        let weekKey = currentWeekKey()
        let docId = "\(userId)_\(weekKey)"
        let fields: [String: FSValue] = [
            "userId":          .string(userId),
            "displayName":     .string(displayName),
            "username":        .string(username),
            "avatarIndex":     .integer(String(avatarIndex)),
            "weeklyVolume":    .double(volume),
            "weeklyWorkouts":  .integer(String(workouts)),
            "weeklyCalories":  .double(calories),
            "weekKey":         .string(weekKey)
        ]
        try await patchDocument(collection: "leaderboard", docId: docId, fields: fields)
    }

    func fetchLeaderboard(friendUserIds: [String]) async throws -> [LeaderboardRow] {
        let weekKey = currentWeekKey()
        guard !friendUserIds.isEmpty else { return [] }
        var rows: [LeaderboardRow] = []
        // Fetch each friend's entry (Firestore REST doesn't support IN queries simply)
        for userId in friendUserIds {
            let docId = "\(userId)_\(weekKey)"
            if let doc = try? await getDocument(collection: "leaderboard", docId: docId),
               let fields = doc.fields as [String: FSValue]? {
                rows.append(LeaderboardRow(
                    id:             fields["userId"]?.stringVal ?? userId,
                    displayName:    fields["displayName"]?.stringVal ?? "Unknown",
                    username:       fields["username"]?.stringVal ?? "",
                    weeklyVolume:   fields["weeklyVolume"]?.doubleVal ?? 0,
                    weeklyWorkouts: fields["weeklyWorkouts"]?.intVal ?? 0,
                    weeklyCalories: fields["weeklyCalories"]?.doubleVal ?? 0,
                    avatarIndex:    fields["avatarIndex"]?.intVal ?? 0
                ))
            }
        }
        return rows
    }

    // MARK: - Friends
    func addFriend(myUserId: String, friendUserId: String, friendName: String,
                   friendUsername: String, friendAvatar: Int) async throws {
        // Create friendship for me → them
        let docA = "\(myUserId)_\(friendUserId)"
        let fieldsA: [String: FSValue] = [
            "userId":         .string(myUserId),
            "friendUserId":   .string(friendUserId),
            "friendName":     .string(friendName),
            "friendUsername": .string(friendUsername),
            "friendAvatar":   .integer(String(friendAvatar))
        ]
        try await patchDocument(collection: "friendships", docId: docA, fields: fieldsA)

        // Also look up my own profile to create friendship them → me
        if let me = try? await getDocument(collection: "users", docId: myUserId),
           let fields = me.fields as [String: FSValue]? {
            let myName     = fields["displayName"]?.stringVal ?? ""
            let myUsername = fields["username"]?.stringVal ?? ""
            let myAvatar   = fields["avatarIndex"]?.intVal ?? 0
            let docB = "\(friendUserId)_\(myUserId)"
            let fieldsB: [String: FSValue] = [
                "userId":         .string(friendUserId),
                "friendUserId":   .string(myUserId),
                "friendName":     .string(myName),
                "friendUsername": .string(myUsername),
                "friendAvatar":   .integer(String(myAvatar))
            ]
            try await patchDocument(collection: "friendships", docId: docB, fields: fieldsB)
        }
    }

    func fetchFriends(myUserId: String) async throws -> [FriendRow] {
        let results = try await runQuery(collectionId: "friendships", field: "userId", op: "EQUAL", value: .string(myUserId))
        return results.compactMap { doc in
            guard let fields = doc.fields as [String: FSValue]? else { return nil }
            return FriendRow(
                id:          fields["friendUserId"]?.stringVal ?? "",
                displayName: fields["friendName"]?.stringVal ?? "Friend",
                username:    fields["friendUsername"]?.stringVal ?? "",
                avatarIndex: fields["friendAvatar"]?.intVal ?? 0
            )
        }
    }

    func removeFriend(myUserId: String, friendUserId: String) async throws {
        try await deleteDocument(collection: "friendships", docId: "\(myUserId)_\(friendUserId)")
        try? await deleteDocument(collection: "friendships", docId: "\(friendUserId)_\(myUserId)")
    }

    // MARK: - REST primitives
    private func patchDocument(collection: String, docId: String, fields: [String: FSValue]) async throws {
        guard isConfigured else { throw FirebaseError.notConfigured }
        let url = URL(string: "\(baseURL)/\(collection)/\(docId)")!
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = FSDocument(fields: fields, name: nil)
        req.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode ?? 0 < 300 else {
            throw FirebaseError.serverError
        }
    }

    private func getDocument(collection: String, docId: String) async throws -> FSDocument {
        guard isConfigured else { throw FirebaseError.notConfigured }
        let url = URL(string: "\(baseURL)/\(collection)/\(docId)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw FirebaseError.notFound
        }
        return try JSONDecoder().decode(FSDocument.self, from: data)
    }

    private func deleteDocument(collection: String, docId: String) async throws {
        guard isConfigured else { throw FirebaseError.notConfigured }
        let url = URL(string: "\(baseURL)/\(collection)/\(docId)")!
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        _ = try await URLSession.shared.data(for: req)
    }

    private func runQuery(collectionId: String, field: String, op: String, value: FSValue) async throws -> [FSDocument] {
        guard isConfigured else { throw FirebaseError.notConfigured }
        let url = URL(string: "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents:runQuery")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let valueJson: Any
        switch value {
        case .string(let v): valueJson = ["stringValue": v]
        case .integer(let v): valueJson = ["integerValue": v]
        case .double(let v): valueJson = ["doubleValue": v]
        case .boolean(let v): valueJson = ["booleanValue": v]
        }

        let query: [String: Any] = [
            "structuredQuery": [
                "from": [["collectionId": collectionId]],
                "where": [
                    "fieldFilter": [
                        "field": ["fieldPath": field],
                        "op": op,
                        "value": valueJson
                    ]
                ]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: query)
        let (data, _) = try await URLSession.shared.data(for: req)
        let results = try JSONDecoder().decode([FSQueryResponse].self, from: data)
        return results.compactMap { $0.document }
    }

    private func currentWeekKey() -> String {
        let cal = Calendar.current
        let week = cal.component(.weekOfYear, from: Date())
        let year = cal.component(.yearForWeekOfYear, from: Date())
        return "\(year)-W\(String(format: "%02d", week))"
    }
}

enum FirebaseError: LocalizedError {
    case notConfigured, notFound, serverError

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Firebase not configured. Add your Project ID in Settings."
        case .notFound:      return "Record not found."
        case .serverError:   return "Server error. Check your Firebase rules are set to test mode."
        }
    }
}
