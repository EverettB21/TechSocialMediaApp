//
//  Post.swift
//  techSocialMediaApp
//
//  Created by Everett Brothers on 11/30/23.
//

import Foundation

struct Post {
    var postid: Int
    var authorUserName: String
    var title: String
    var body: String
    var createdDate: String
    var authorUserId: UUID
    var numComments: Int
    var likes: Int
    var userLiked: Bool
}

extension Post: Codable { 
    enum CodingKeys: String, CodingKey {
        case postid
        case title
        case body
        case authorUserName
        case authorUserId
        case likes
        case userLiked
        case numComments
        case createdDate
    }
}

extension Post: Hashable {
    
}

struct CreatePostData: Codable {
    var userSecret: UUID
    var post: CreatePost
}

struct CreatePost: Codable {
    var title: String
    var body: String
}

struct EditPost: Codable {
    var postid: Int
    var title: String
    var body: String
}

struct EditPostData: Codable {
    var userSecret: UUID
    var post: EditPost
}

struct DeletePostData: Codable {
    var userSecret: UUID
    var postid: Int
}
