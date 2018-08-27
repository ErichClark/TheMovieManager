//
//  Codable Structs.swift
//  TheMovieManager
//
//  Created by Erich Clark on 8/20/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

import Foundation

// MARK: - Config

struct Config: Codable {
    var images: Images
}

struct Images: Codable {
    var base_url: String
    var secure_base_url: String
    var poster_sizes: [String]
    var profile_sizes: [String]
}

// MARK: - Request Token

struct RequestToken: Codable {
    var success: Bool?
    var expires_at: String?
    var request_token: String?
}

// MARK: - Validate With Login

struct Validate_With_Login: Codable {
    var success: Bool?
    var expires_at: String?
    var request_token: String?
}

// MARK: - Session ID

struct SessionID: Codable {
    var success: Bool?
    var session_id: String?
}

// MARK: - Account

struct Account: Codable {
    var id: Int?
    var iso_639_1: String?
    var iso_3166_1: String?
    var name: String?
    var include_adult: Bool?
    var username: String?
}

// MARK: - Genre

struct Genre: Codable {
    var id: Int?
    var page: Int?
    var results: [Movie]?
}

// MARK: - Movie

struct Movies: Codable {
    var movies: [Movie]?
}

struct Movie: Codable {
    let title: String?
    let id: Int?
    let poster_path: String?
    
}

extension Movie: Equatable {}

func ==(lhs: Movie, rhs: Movie) -> Bool {
    return lhs.id == rhs.id
}

// MARK: - Favorites

struct Favorites: Codable {
    var page: Int?
    var results: [Movie]?
    var total_pages: Int?
    var total_results: Int?
}

struct Favorite: Codable {
    var media_type: String?
    var media_id: Int?
    var favorite: Bool?
}

struct FavoriteResponse: Codable {
    var status_code: Int?
    var status_message: String?
}
