//
//  Coordinator.swift
//  EmojiHunter
//
//  Created by lama alemadi on 08/11/2026.
//

import SwiftUI

// Passes a successful camera match back to the SwiftUI game state.
class Coordinator: NSObject, EmojiFoundDelegate {
    @Binding var emojiFound: EmojiSearch

    init(emojiFound: Binding<EmojiSearch>) {
        _emojiFound = emojiFound
    }

    func emojiWasFound(result: Bool) {
        // Only accept a match while the player is still searching.
        guard result, emojiFound == .searching else { return }

        print("emojiWasFound \(result)")
        emojiFound = .found
    }
}
