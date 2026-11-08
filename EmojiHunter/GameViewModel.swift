//
//  GameViewModel.swift
//  EmojiHunter
//
//  Created by lama alemadi on 08/11/2026.
//

import SwiftUI
import Observation
import Combine

// Stores the current round and the state shown by SwiftUI.
@Observable
class GameViewModel {
    static let roundDuration = 10

    var currentLevel = 0
    var showNext = false
    var timeRemaining = GameViewModel.roundDuration
    var emojiStatus: EmojiSearch = .searching

    // The timer sends one tick per second. Step 7 connects it.
    @ObservationIgnored
    var timer = Timer.publish(every: 1, on: .main, in: .common)

    @ObservationIgnored
    private var timerConnection: (any Cancellable)?
    // Prepare a fresh timer for the next round.
    func instantiateTimer() {
        cancelTimer()
        timer = Timer.publish(every: 1, on: .main, in: .common)
    }

    // Start the countdown when the timer appears on screen.
    func connectTimer() {
        guard timerConnection == nil else { return }
        timerConnection = timer.connect()
    }

    // Stop the active countdown and release its connection.
    func cancelTimer() {
        timerConnection?.cancel()
        timerConnection = nil
    }

    // Update the game state each time the timer ticks.
    func adjustTime() {
        if emojiStatus == .found {
            cancelTimer()
            timeRemaining = Self.roundDuration
            return
        }

        guard emojiStatus == .searching else { return }

        timeRemaining = max(0, timeRemaining - 1)

        // End the round on the tick that reaches zero.
        if timeRemaining == 0 {
            cancelTimer()
            emojiStatus = .notFound
            showNext = true
        }
    }
    // Move to the next emoji or end the game after the last one.
    func startSearch() {
        if currentLevel == emojiObjects.count - 1 {
            emojiStatus = .gameOver
        } else {
            currentLevel += 1
            startRound()
        }
    }

    // Start again from the first emoji.
    func restartGame() {
        currentLevel = 0
        startRound()
    }

    // Give the player a fresh 10 seconds for the current emoji.
    func startRound() {
        timeRemaining = Self.roundDuration
        emojiStatus = .searching
        showNext = false
        instantiateTimer()
    }

    // Show the target emoji or the result of the round.
    func emojiResultText() -> Text {
        let emoji = emojiObjects[currentLevel].emoji

        switch emojiStatus {
        case .found:
            return Text("\(emoji) is FOUND")
                .font(.system(size: 50, design: .rounded))
                .fontWeight(.bold)

        case .notFound:
            return Text("\(emoji) NOT FOUND")
                .font(.system(size: 50, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.red)

        default:
            return Text(emoji)
                .font(.system(size: 50, design: .rounded))
                .fontWeight(.bold)
        }
    }
}
