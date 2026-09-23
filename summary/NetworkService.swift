//
//  NetworkService.swift
//  summary
//
//  Created by Damir Aushenov on 21/9/26.
//



import Foundation
import FoundationModels

enum AppConfiguration {

    static let backendURL = URL(

        string: "https://summarizer-ncdy.onrender.com"

    )!

}

struct AppleIntelligenceService {

    var isAvailable: Bool {

        SystemLanguageModel.default.availability

            == .available

    }

}

struct Streamer: Decodable, Identifiable {
    let id: String
    let login: String
    let name: String
    let title: String
    let game: String
    let viewers: Int
    let thumbnail: String
}

import Foundation

struct TwitchVideo: Decodable, Identifiable {
    let id: String
    let title: String
    let url: String
    let thumbnail: String
    let duration: String
    let createdAt: String
    let views: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case thumbnail
        case duration
        case views

        case createdAt = "created_at"
    }
}


struct VideoInfoRequest: Encodable {
    let url: String
}


struct VideoInfo: Decodable {
    let title: String?
    let duration: Int
}


struct AudioChunkRequest: Encodable {
    let url: String
    let start: Int
    let duration: Int
}


final class TwitchService {

    private let baseURL =
    AppConfiguration.backendURL


    func getVideoInfo(
        twitchURL: String
    ) async throws -> VideoInfo {

        let endpoint = URL(
            string: "\(baseURL)/video/info"
        )!

        var request = URLRequest(
            url: endpoint
        )

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody =
            try JSONEncoder().encode(
                VideoInfoRequest(
                    url: twitchURL
                )
            )

        let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard
            let httpResponse =
                response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw URLError(
                .badServerResponse
            )
        }

        return try JSONDecoder().decode(
            VideoInfo.self,
            from: data
        )
    }


    func downloadAudioChunk(
        twitchURL: String,
        start: Int,
        duration: Int
    ) async throws -> URL {

        let endpoint = URL(
            string: "\(baseURL)/audio/chunk"
        )!

        var request = URLRequest(
            url: endpoint
        )

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody =
            try JSONEncoder().encode(
                AudioChunkRequest(
                    url: twitchURL,
                    start: start,
                    duration: duration
                )
            )

        // Give Twitch/backend enough time
        request.timeoutInterval = 120

        let (tempURL, response) =
            try await URLSession.shared.download(
                for: request
            )

        guard
            let httpResponse =
                response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw URLError(
                .badServerResponse
            )
        }

        return tempURL
    }
    
    func getStreamers(
        language: String = "ru"
    ) async throws -> [Streamer] {

        var components = URLComponents(
            string: "\(baseURL)/streamers"
        )!

        components.queryItems = [
            URLQueryItem(
                name: "language",
                value: language
            )
        ]

        let (data, response) =
            try await URLSession.shared.data(
                from: components.url!
            )

        guard
            let response = response as? HTTPURLResponse,
            response.statusCode == 200
        else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(
            [Streamer].self,
            from: data
        )
    }
    
    func getVideos(
        userID: String
    ) async throws -> [TwitchVideo] {

        let url = URL(
            string:
                "\(baseURL)/streamers/\(userID)/videos"
        )!

        let (data, response) =
            try await URLSession.shared.data(
                from: url
            )

        guard
            let response =
                response as? HTTPURLResponse,
            response.statusCode == 200
        else {
            throw URLError(
                .badServerResponse
            )
        }

        return try JSONDecoder().decode(
            [TwitchVideo].self,
            from: data
        )
    }
}
