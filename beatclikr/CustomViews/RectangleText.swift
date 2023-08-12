//
//  RegularButton.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import SwiftUI

struct RectangleText: View {
    var text: String
    var backgroundColor: Color = .blue
    var foregroundColor: Color = .white
    
    init (_ text: String) {
        self.text = text
    }
    
    init (_ text: String, backgroundColor: Color, foregroundColor: Color) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
                .fill(self.backgroundColor)
                .frame(height: 40)
                .shadow(radius: 2)
            
            Text(self.text)
                .foregroundColor(self.foregroundColor)
                .bold()
        }
    }
}

#Preview {
    RectangleText("Bye!")
}
