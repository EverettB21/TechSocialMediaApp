//
//  Profile.swift
//  techSocialMediaApp
//
//  Created by Everett Brothers on 11/30/23.
//

import Foundation

struct Profile {
    var userName: String
    var bio: String
    var techInterests: String
}

extension Profile: Codable { }

struct UserUpdateProfile {
    var userSecret: UUID
    var profile: Profile
}

extension UserUpdateProfile: Codable { }
