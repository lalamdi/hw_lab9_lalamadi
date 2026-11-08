//
//  Emoji.swift
//  EmojiHunter
//
//  Created by lama alemadi on 08/11/2026.
//

import Foundation

// The camera uses this delegate to report a match.
// AnyObject lets the camera controller hold the delegate weakly.
protocol EmojiFoundDelegate: AnyObject {
    func emojiWasFound(result: Bool)
}

// The possible states of the game.
enum EmojiSearch {
    case found
    case notFound
    case searching
    case gameOver
}

// An emoji and the object the player needs to find.
struct EmojiModel: Identifiable {
    let id = UUID()
    var emoji: String      // The symbol shown on the screen.
    var emojiName: String  // The label to look for in MobileNetV2's prediction.
}

// The game goes through these targets in order.
let emojiObjects: [EmojiModel] = [
    EmojiModel(emoji: "💻", emojiName: "laptop"),
    EmojiModel(emoji: "🖊️", emojiName: "ballpoint"),
    EmojiModel(emoji: "☕️", emojiName: "coffee mug"),
    EmojiModel(emoji: "⌨️", emojiName: "computer keyboard"),
    EmojiModel(emoji: "🍌", emojiName: "banana")
]
