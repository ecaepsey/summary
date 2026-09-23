//
//  TranscriptionService.swift
//  summary
//
//  Created by Damir Aushenov on 21/9/26.
//

import Foundation


import WhisperKit

import Foundation
import WhisperKit

final class TranscriptionService {

    private var whisperKit: WhisperKit?

    func setup() async throws {
        whisperKit = try await WhisperKit(
            model: "tiny"
        )
    }

    func transcribe(audioURL: URL) async throws -> String {
        guard let whisperKit else {
            throw TranscriptionError.notInitialized
        }
        
        let options = DecodingOptions(

              language: "ru"

          )

        let results = try await whisperKit.transcribe(
            audioPath: audioURL.path,
            decodeOptions: options
        )

        return results
            .map(\.text)
            .joined(separator: " ")
    }
}

enum TranscriptionError: Error {
    case notInitialized
}


import FoundationModels

import Foundation




final class SummaryService {

    private let session = LanguageModelSession()


    // MARK: - Chunk summary

    func summarize(
        _ transcript: String
    ) async throws -> String {

        let prompt = """
        You are summarizing a transcript from a Twitch stream.

        Create a concise summary of what happened in this segment.

        Include:
        - main topics discussed
        - important opinions or arguments
        - interesting or funny moments
        - important events

        Ignore transcription mistakes,
        filler words, repetitions,
        greetings and meaningless fragments.

        Write the summary in the same language
        as the transcript.

        Transcript:

        \(transcript)
        """

        let response =
            try await session.respond(
                to: prompt
            )

        return response.content
    }


    // MARK: - Final summary

    func createFinalSummary(
        _ summaries: String
    ) async throws -> String {

        let prompt = """
        Below are chronological summaries of
        different parts of one Twitch stream.

        Create one coherent summary of the
        entire stream.

        Include:

        1. Main topics
        2. Most important discussions
        3. Interesting or funny moments
        4. Important conclusions
        5. Key moments with timestamps

        Remove duplicated information.

        Keep useful timestamps.

        Write in the same language as
        the summaries.

        Chunk summaries:

        \(summaries)
        """

        let response =
            try await session.respond(
                to: prompt
            )

        return response.content
    }
}
