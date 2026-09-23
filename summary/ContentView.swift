import SwiftUI

struct ContentView: View {

    @StateObject
    private var viewModel = StreamViewModel()

    private let columns = [
        GridItem(
            .adaptive(minimum: 280),
            spacing: 16
        )
    ]

    var body: some View {

        NavigationStack {

            ScrollView {

                LazyVGrid(
                    columns: columns,
                    spacing: 20
                ) {

                    ForEach(viewModel.streamers) { streamer in

                        NavigationLink {

                            StreamerVideosView(
                                streamer: streamer
                            )

                        } label: {

                            StreamerCard(
                                streamer: streamer
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Popular Streams")
            .overlay {

                if viewModel.streamers.isEmpty {

                    ProgressView(
                        "Loading streams..."
                    )
                }
            }
            .task {
                await viewModel.loadStreamers()
            }
            .refreshable {
                await viewModel.loadStreamers()
            }
        }
    }
}
