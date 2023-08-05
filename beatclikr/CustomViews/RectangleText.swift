//
//  RegularButton.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import SwiftUI

struct RectangleText: View {
    var text: String
    var color: Color = .blue
    
    init (_ text: String) {
        self.text = text
    }
    
    init (_ text: String, color: Color) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(self.color)
                .frame(height: 40)
                .cornerRadius(5)
            Text(self.text)
                .foregroundColor(.white)
                .bold()
        }
    }
}

#Preview {
    RectangleText("Bye!")
}
