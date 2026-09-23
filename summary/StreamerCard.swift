//
//  StreamerCard.swift
//  summary
//
//  Created by Damir Aushenov on 21/9/26.
//

import Foundation


import SwiftUI

struct StreamerCard: View {

    let streamer: Streamer

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            AsyncImage(
                url: URL(
                    string: streamer.thumbnail
                )
            ) { image in

                image
                    .resizable()
                    .scaledToFill()

            } placeholder: {

                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        ProgressView()
                    }
            }
            .frame(height: 170)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12
                )
            )

            Text(streamer.name)
                .font(.headline)

            Text(streamer.title)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.secondary)

            HStack {

                Text(streamer.game)

                Spacer()

                Text(
                    "\(formatViewers(streamer.viewers)) viewers"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func formatViewers(
        _ viewers: Int
    ) -> String {

        if viewers >= 1_000 {

            return String(
                format: "%.1fK",
                Double(viewers) / 1_000
            )
        }

        return "\(viewers)"
    }
}
