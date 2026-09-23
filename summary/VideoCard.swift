//
//  VideoCard.swift
//  summary
//
//  Created by Damir Aushenov on 21/9/26.
//

import Foundation


import SwiftUI

struct VideoCard: View {

    let video: TwitchVideo

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            AsyncImage(
                url: URL(string: video.thumbnail)
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
            .frame(height: 200)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12
                )
            )

            Text(video.title)
                .font(.headline)
                .lineLimit(2)

            HStack {

                Text(video.duration)

                Spacer()

                Text("\(video.views) views")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
