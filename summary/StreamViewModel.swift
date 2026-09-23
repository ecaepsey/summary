//
//  StreamViewModel.swift
//  summary
//
//  Created by Damir Aushenov on 21/9/26.
//


import SwiftUI
import Foundation
import Combine

enum ProcessingStage: Equatable {
    case idle
    case loadingVideo
    case downloading
    case transcribing
    case summarizing
    case creatingFinalSummary
    case finished
    case failed(String)
}



struct ChunkSummary: Identifiable {

    let id = UUID()

    let start: Int

    let end: Int

    let text: String

    var timeRange: String {

        "\(format(start)) – \(format(end))"

    }

    private func format(_ seconds: Int) -> String {

        let hours = seconds / 3600

        let minutes = (seconds % 3600) / 60

        if hours > 0 {

            return String(

                format: "%d:%02d:00",

                hours,

                minutes

            )

        }

        return String(

            format: "%02d:00",

            minutes

        )

    }

}


@MainActor
final class StreamViewModel: ObservableObject {

    // MARK: - UI State

    @Published var stage: ProcessingStage = .idle

    @Published var currentChunk = 0
    @Published var totalChunks = 0

    @Published var currentStart = 0
    @Published var currentEnd = 0

    @Published var chunkSummaries: [ChunkSummary] = []

    @Published var finalSummary = ""


    // MARK: - Services

    private let twitchService = TwitchService()
    private let transcriptionService = TranscriptionService()
    private let summaryService = SummaryService()
    
    @Published var isWhisperReady = false
    @Published var whisperLoading = false

    @Published var streamers: [Streamer] = []

    func loadStreamers() async {
        do {
            streamers = try await twitchService.getStreamers()

            print("STREAMERS:", streamers.count)

            for streamer in streamers {
                print(
                    streamer.name,
                    streamer.viewers,
                    streamer.game
                )
            }
        } catch {
            print("❌ STREAMERS:", error)
        }
    }

    func prepareWhisper() async {
        guard !isWhisperReady,
              !whisperLoading else {
            return
        }

        whisperLoading = true

        do {
            let start = Date()

            try await transcriptionService.setup()

            print(
                "⏱ Whisper setup:",
                Date().timeIntervalSince(start),
                "seconds"
            )

            isWhisperReady = true
            whisperLoading = false

        } catch {
            whisperLoading = false
            print("❌ Whisper setup:", error)
        }
    }


    // MARK: - Progress

    var progress: Double {
        guard totalChunks > 0 else {
            return 0
        }

        return Double(currentChunk) /
               Double(totalChunks)
    }


    var statusText: String {

        switch stage {

        case .idle:
            return "Ready"

        case .loadingVideo:
            return "Getting stream information..."

        case .downloading:
            return """
            Downloading \(currentChunk) of \(totalChunks)
            """

        case .transcribing:
            return """
            Transcribing \(currentChunk) of \(totalChunks)
            """

        case .summarizing:
            return """
            Summarizing \(currentChunk) of \(totalChunks)
            """

        case .creatingFinalSummary:
            return "Creating final summary..."

        case .finished:
            return "Done"

        case .failed(let message):
            return "Error: \(message)"
        }
    }


    var currentTimeRange: String {

        guard currentEnd > currentStart else {
            return ""
        }

        return "\(format(currentStart)) – \(format(currentEnd))"
    }
    
    private let appleIntelligence =

        AppleIntelligenceService()

    // MARK: - Process

    func process(twitchURL: String) async {
        
        
        guard appleIntelligence.isAvailable else {

            stage = .failed(

                "Apple Intelligence is not available on this device."

            )

            return

        }
     

        guard !twitchURL.isEmpty else {
            return
        }

        do {

            // Reset previous result

            stage = .loadingVideo

            currentChunk = 0
            totalChunks = 0

            chunkSummaries = []
            finalSummary = ""


            // MARK: WhisperKit setup

          

            // MARK: Get video info

            let info = try await twitchService.getVideoInfo(
                twitchURL: twitchURL
            )

            print(
                "VIDEO:",
                info.title ?? "Unknown"
            )

            print(
                "DURATION:",
                info.duration
            )


            // MARK: Create chunks

            let chunkSize = 300

            let starts = Array(
                stride(
                    from: 0,
                    to: info.duration,
                    by: chunkSize
                )
            )

            totalChunks = starts.count

            print(
                "TOTAL CHUNKS:",
                totalChunks
            )


            // MARK: Process chunks

            for (index, start) in starts.enumerated() {

                currentChunk = index + 1
                currentStart = start

                let remaining =
                    info.duration - start

                let duration = min(
                    chunkSize,
                    remaining
                )

                currentEnd = start + duration


                // Download

                stage = .downloading

                print(
                    "⬇️ Downloading:",
                    start,
                    "→",
                    currentEnd
                )

                let audioURL =
                    try await twitchService
                        .downloadAudioChunk(
                            twitchURL: twitchURL,
                            start: start,
                            duration: duration
                        )


                // Transcribe

                stage = .transcribing

                let transcriptionStart = Date()

                let transcript =
                    try await transcriptionService
                        .transcribe(
                            audioURL: audioURL
                        )

                let transcriptionTime =
                    Date().timeIntervalSince(
                        transcriptionStart
                    )

                print(
                    "⏱ Transcription:",
                    transcriptionTime,
                    "seconds"
                )


                // Audio is no longer needed

                try? FileManager.default.removeItem(
                    at: audioURL
                )


                // Summarize chunk

                stage = .summarizing

                let summaryStart = Date()

                let summary =
                    try await summaryService.summarize(
                        transcript
                    )

                let summaryTime =
                    Date().timeIntervalSince(
                        summaryStart
                    )

                print(
                    "⏱ Summary:",
                    summaryTime,
                    "seconds"
                )


                // Save summary

                let chunkSummary = ChunkSummary(
                    start: start,
                    end: currentEnd,
                    text: summary
                )

                chunkSummaries.append(
                    chunkSummary
                )

                print(
                    "✅ Chunk",
                    currentChunk,
                    "complete"
                )
            }


            // MARK: Final summary

            stage = .creatingFinalSummary

            let combinedSummaries =
                chunkSummaries
                    .map {
                        """
                        [\($0.timeRange)]
                        \($0.text)
                        """
                    }
                    .joined(
                        separator: "\n\n"
                    )

            finalSummary =
                try await summaryService
                    .createFinalSummary(
                        combinedSummaries
                    )

            stage = .finished

        } catch {

            print(
                "❌ ERROR:",
                error
            )

            stage = .failed(
                error.localizedDescription
            )
        }
    }


    // MARK: - Formatting

    private func format(
        _ seconds: Int
    ) -> String {

        let hours = seconds / 3600

        let minutes =
            (seconds % 3600) / 60

        if hours > 0 {

            return String(
                format: "%d:%02d:00",
                hours,
                minutes
            )
        }

        return String(
            format: "%02d:00",
            minutes
        )
    }
}
