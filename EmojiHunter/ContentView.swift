//
//  ContentView.swift
//  EmojiHunter
//
//  Created by lama alemadi on 08/11/2026.
//

import SwiftUI

struct ContentView: View {
    // Step 9: Keep the game state for this screen.
    @State private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            // Step 10: Show NEXT after a round, or show the camera.
            if (viewModel.showNext || viewModel.emojiStatus == .found)
                && viewModel.emojiStatus != .gameOver {
                Color.black.ignoresSafeArea()

                Button("NEXT") {
                    viewModel.startSearch()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            } else {
                CustomCameraRepresentable(
                    emojiString: emojiObjects[viewModel.currentLevel].emojiName,
                    emojiFound: $viewModel.emojiStatus
                )
                // Create a fresh camera controller for each target.
                .id(viewModel.currentLevel)
                .ignoresSafeArea()
            }

            // Step 11: Put the countdown, emoji, or restart button at the bottom.
            VStack {
                Spacer()

                if viewModel.emojiStatus == .gameOver {
                    Button {
                        viewModel.restartGame()
                    } label: {
                        Text("GAME OVER\nTap to restart")
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    if viewModel.emojiStatus == .searching {
                        Text("\(viewModel.timeRemaining)")
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.yellow)
                            .onReceive(viewModel.timer) { _ in
                                viewModel.adjustTime()
                            }
                            .onAppear { viewModel.connectTimer() }
                            .onDisappear { viewModel.cancelTimer() }
                    }

                    viewModel.emojiResultText()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
    }
}
