//
//  EmojiHunterTests.swift
//  EmojiHunterTests
//
//  Created by lama alemadi on 08/11/2026.
//

import Testing
@testable import EmojiHunter

@MainActor
struct GameViewModelTests {
    @Test func startingStateIsSearching() {
        let vm = GameViewModel()

        #expect(vm.emojiStatus == .searching)
        #expect(vm.currentLevel == 0)
        #expect(vm.timeRemaining == GameViewModel.roundDuration)
    }

    @Test func adjustTimeDecrementsWhileSearching() {
        let vm = GameViewModel()
        let startingTime = vm.timeRemaining

        vm.adjustTime()

        #expect(vm.timeRemaining == startingTime - 1)
    }

    @Test func adjustTimeMarksNotFoundWhenTimeExpires() {
        let vm = GameViewModel()
        vm.timeRemaining = 0

        vm.adjustTime()

        #expect(vm.emojiStatus == .notFound)
        #expect(vm.showNext == true)
    }

    @Test func adjustTimeResetsWhenFound() {
        let vm = GameViewModel()
        vm.emojiStatus = .found
        vm.timeRemaining = 3

        vm.adjustTime()

        #expect(vm.timeRemaining == GameViewModel.roundDuration)
    }

    @Test func startSearchAdvancesLevel() {
        let vm = GameViewModel()

        vm.startSearch()

        #expect(vm.currentLevel == 1)
        #expect(vm.emojiStatus == .searching)
    }

    @Test func restartGameResetsLevel() {
        let vm = GameViewModel()
        vm.currentLevel = 3

        vm.restartGame()

        #expect(vm.currentLevel == 0)
        #expect(vm.emojiStatus == .searching)
    }
}
