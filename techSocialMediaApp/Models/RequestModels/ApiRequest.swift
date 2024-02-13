//
//  ApiRequest.swift
//  techSocialMediaApp
//
//  Created by Everett Brothers on 11/30/23.
//

import Foundation

protocol APIRequest {
    associatedtype Response
    
    var path: String { get }
    var queryItems: [URLQueryItem]? { get }
    var request: URLRequest { get }
    var postData: Data? { get }
    var httpMethod: String { get }
}

extension APIRequest {
    var queryItems: [URLQueryItem]? { nil }
    var postData: Data? { nil }
    var httpMethod: String { "POST" }
}

extension APIRequest {
    var request: URLRequest {
        var components = URLComponents(string: "\(API.url)")!
        
        components.path = path
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        
        if let data = postData {
            request.httpBody = data
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = httpMethod
        }
        
        return request
    }
}

enum APIRequestError: Error {
    case itemsNotFound
    case requestFailed
}

extension APIRequest where Response: Decodable {
    func send() async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIRequestError.itemsNotFound
        }
        
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        
        return decoded
    }
}

extension APIRequest {
    func send() async throws -> Void {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let str = String(data: data, encoding: .utf8)
        if str != nil {
            print(str!)
        }
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIRequestError.requestFailed
        }
    }
}
