//
//  Requests.swift
//  techSocialMediaApp
//
//  Created by Everett Brothers on 11/30/23.
//

import Foundation

struct UserProfileRequest: APIRequest {
    typealias Response = UserProfile
    
    var userUUID: UUID
    var userSecret: UUID
    
    var path: String { "/userProfile" }
    
    var queryItems: [URLQueryItem]? { ["userUUID": "\(userUUID)", "userSecret": "\(userSecret)"].map { URLQueryItem(name: $0.key, value: $0.value) } }
}

struct UpdateProfileRequest: APIRequest {
    typealias Response = Void
    
    var userSecret: UUID
    var profile: Profile
    
    var userUpdateProfile: UserUpdateProfile { UserUpdateProfile(userSecret: userSecret, profile: profile) }
    
    var path: String { "/updateProfile" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(userUpdateProfile)
    }
}

struct PostsRequest: APIRequest {
    typealias Response = [Post]
    
    var userSecret: UUID
    var pageNumber: Int
    
    var path: String { "/posts" }
    
    var queryItems: [URLQueryItem]? { ["userSecret": "\(userSecret)", "pageNumber": "\(pageNumber)"].map { URLQueryItem(name: $0.key, value: $0.value) } }
}

struct CreatePostRequest: APIRequest {
    typealias Response = Void
    
    var userSecret: UUID
    var post: CreatePost
    
    var createPostData: CreatePostData { CreatePostData(userSecret: userSecret, post: post) }
    
    var path: String { "/createPost" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(createPostData)
    }
}

struct CommentsRequest: APIRequest {
    typealias Response = [Comment]
    
    var userSecret: UUID
    var postid: Int
    var pageNumber: Int
    
    var path: String { "/comments" }
    
    var queryItems: [URLQueryItem]? { ["userSecret": "\(userSecret)", "postid": "\(postid)", "pageNumber": "\(pageNumber)"].map { URLQueryItem(name: $0.key, value: $0.value) } }
}

struct CreateCommentRequest: APIRequest {
    typealias Response = Void
    
    var userSecret: UUID
    var commentBody: String
    var postid: Int
    
    var createCommentData: CreateCommentData { CreateCommentData(userSecret: userSecret, commentBody: commentBody, postid: postid) }
    
    var path: String { "/createComment" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(createCommentData)
    }
}

struct UpdatePostLikesRequest: APIRequest {
    typealias Response = Void
    
    var userSecret: UUID
    var postid: Int
    
    var updateLikesData: UpdateLikesData { UpdateLikesData(userSecret: userSecret, postid: postid) }
    
    var path: String { "/updateLikes" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(updateLikesData)
    }
}

struct UserPostsRequest: APIRequest {
    typealias Response = [Post]
    
    var userSecret: UUID
    var userUUID: UUID
    var pageNumber: Int
    
    var path: String { "/userPosts" }
    
    var queryItems: [URLQueryItem]? { ["userSecret": "\(userSecret)", "userUUID": "\(userUUID)", "pageNumber": "\(pageNumber)"].map { URLQueryItem(name: $0.key, value: $0.value) } }
}

struct DeletePostRequest: APIRequest {
    typealias Response = Void
    
    var userSecret: UUID
    var postid: Int
    
    var updateLikesData: DeletePostData { DeletePostData(userSecret: userSecret, postid: postid) }
    
    var queryItems: [URLQueryItem]? { ["userSecret": "\(userSecret)", "postid": "\(postid)"].map { URLQueryItem(name: $0.key, value: $0.value) } }
    
    var path: String { "/post" }
    
    var httpMethod: String { "DELETE" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(updateLikesData)
    }
}

struct EditPostRequest: APIRequest {
    typealias Response = Void
    
    var userSecret: UUID
    var post: EditPost
    
    var createPostData: EditPostData { EditPostData(userSecret: userSecret, post: post) }
    
    var path: String { "/editPost" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(createPostData)
    }
}
