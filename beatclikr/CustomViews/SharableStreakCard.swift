//
//  SharableStreakCard.swift
//  beatclikr
//
//  Created by Ben Funk on 5/2/26.
//

import SwiftUI

struct SharableStreakCard: View {
    var streakDays: String

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.black, .blue, .black]),
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(spacing: 12) {
                ZStack {
                    Image(systemName: ImageConstants.streak)
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundColor(.accentColor.opacity(0.8))
                        .blur(radius: 8)
                        .scaleEffect(1.1)

                    Image(systemName: ImageConstants.streak)
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundColor(.accentColor)
                }
                Text(streakDays)
                    .font(.system(size: 105, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundColor(.white)
                Text("day streak")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(height: 1)
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.horizontal, 80)
                HStack(spacing: 8) {
                    if let uiImage = UIImage(named: "appicondisplay") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Text("BeatClikr")
                        .foregroundColor(.white.opacity(0.85))
                        .font(Font.system(size: 14, weight: .medium))
                }
            }
        }
        .frame(width: 360, height: 360)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SharableStreakCard(streakDays: "180")
}
