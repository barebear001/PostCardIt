//
//  PostcardModel.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/3/25.
//

// PostcardModel.swift
import Foundation

struct Postcard: Hashable, Identifiable, Codable {
    var id: String
    var senderId: String
    var senderName: String
    var recipientId: String?
    var recipientName: String
    var message: String
    var country: String
    var imageKey: String?
    var createdAt: Date
    var isSent: Bool
    
    init(id: String = UUID().uuidString,
         senderId: String,
         senderName: String,
         recipientId: String? = nil,
         recipientName: String,
         message: String,
         country: String,
         imageKey: String? = nil,
         createdAt: Date = Date(),
         isSent: Bool = false) {
        self.id = id
        self.senderId = senderId
        self.senderName = senderName
        self.recipientId = recipientId
        self.recipientName = recipientName
        self.message = message
        self.country = country
        self.imageKey = imageKey
        self.createdAt = createdAt
        self.isSent = isSent
    }
}
