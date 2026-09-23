//
//  StreamerVideosView.swift
//  summary
//
//  Created by Damir Aushenov on 21/9/26.
//

import Foundation


import SwiftUI

struct StreamerVideosView: View {

    let streamer: Streamer

    @State
    private var videos: [TwitchVideo] = []

    @State
    private var isLoading = true

    @State
    private var errorMessage: String?

    private let twitchService =
        TwitchService()

    var body: some View {

        ScrollView {

            LazyVStack(spacing: 20) {
                ForEach(videos) { video in

                    NavigationLink {

                        VideoSummaryView(
                            video: video
                        )

                    } label: {

                        VideoCard(video: video)
                    }
                    .buttonStyle(.plain)
                }
               
                
            }
            .padding()
        }
        .navigationTitle(streamer.name)
        .overlay {

            if isLoading {
                ProgressView(
                    "Loading videos..."
                )
            }
        }
        .task {
            await loadVideos()
        }
    }

    private func loadVideos() async {

        isLoading = true

        do {
            videos =
                try await twitchService
                    .getVideos(
                        userID: streamer.id
                    )

            print(
                "VIDEOS:",
                videos.count
            )

        } catch {

            print(
                "❌ VIDEOS:",
                error
            )

            errorMessage =
                error.localizedDescription
        }

        isLoading = false
    }
}
