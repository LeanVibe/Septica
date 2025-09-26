import SwiftUI

struct RomanianDialogueBubbleView: View {
    let dialogue: String
    let character: RomanianCharacterAvatar

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(character.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(dialogue)
                .font(.body)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.6)))
                .foregroundColor(.white)
        }
    }
}
