//
//  CustomCameraRepresentable.swift
//  EmojiHunter
//
//  Created by lama alemadi on 08/11/2026.
//

import SwiftUI

// Displays the UIKit camera controller inside SwiftUI.
struct CustomCameraRepresentable: UIViewControllerRepresentable {
    var emojiString: String
    @Binding var emojiFound: EmojiSearch

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController(emoji: emojiString)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(
        _ cameraViewController: CameraViewController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(emojiFound: $emojiFound)
    }
}
