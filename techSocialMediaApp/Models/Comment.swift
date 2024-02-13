//
//  Comment.swift
//  techSocialMediaApp
//
//  Created by Everett Brothers on 11/30/23.
//

import Foundation

struct Comment {
    var commentId: Int
    var body: String
    var userName: String
    var userId: UUID
    var createdDate: String
}

extension Comment: Codable { }

extension Comment: Hashable { }

struct CreateCommentData: Codable {
    var userSecret: UUID
    var commentBody: String
    var postid: Int
}
