//
//  VideoSummaryView.swift
//  summary
//
//  Created by Damir Aushenov on 21/9/26.
//

import Foundation


import SwiftUI

struct VideoSummaryView: View {

    let video: TwitchVideo

    @StateObject
    private var viewModel = StreamViewModel()

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                AsyncImage(
                    url: URL(string: video.thumbnail)
                ) { image in

                    image
                        .resizable()
                        .scaledToFit()

                } placeholder: {

                    Rectangle()
                        .fill(.quaternary)
                        .aspectRatio(
                            16 / 9,
                            contentMode: .fit
                        )
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )

                Text(video.title)
                    .font(.title2.bold())

                Text(video.duration)
                    .foregroundStyle(.secondary)

                if viewModel.whisperLoading {

                    HStack {

                        ProgressView()

                        Text(
                            "Preparing transcription model..."
                        )
                    }

                } else if !viewModel.isWhisperReady {

                    Button("Prepare") {

                        Task {
                            await viewModel.prepareWhisper()
                        }
                    }

                } else {

                    Button {

                        Task {
                            await viewModel.process(
                                twitchURL: video.url
                            )
                        }

                    } label: {

                        Text("Summarize")
                            .frame(
                                maxWidth: .infinity
                            )
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing)
                }

                if isProcessing {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text(viewModel.statusText)
                            .font(.headline)

                        Text(
                            viewModel.currentTimeRange
                        )
                        .foregroundStyle(.secondary)

                        ProgressView(
                            value: viewModel.progress
                        )

                        Text(
                            "\(viewModel.currentChunk) / \(viewModel.totalChunks) chunks"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if !viewModel.finalSummary.isEmpty {

                    Divider()

                    Text("Summary")
                        .font(.title2.bold())

                    Text(
                        viewModel.finalSummary
                    )
                }

                if !viewModel.chunkSummaries.isEmpty {

                    Divider()

                    Text("Timeline")
                        .font(.title2.bold())

                    ForEach(
                        viewModel.chunkSummaries
                    ) { chunk in

                        VStack(
                            alignment: .leading,
                            spacing: 6
                        ) {

                            Text(chunk.timeRange)
                                .font(.headline)

                            Text(chunk.text)
                                .foregroundStyle(
                                    .secondary
                                )
                        }

                        Divider()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.prepareWhisper()
        }
    }

    private var isProcessing: Bool {

        switch viewModel.stage {

        case .loadingVideo,
             .downloading,
             .transcribing,
             .summarizing,
             .creatingFinalSummary:

            return true

        default:
            return false
        }
    }
}
