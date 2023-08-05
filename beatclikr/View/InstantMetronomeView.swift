//
//  InstantMetronomeView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftUI
import Awesome

struct InstantMetronomeView: View {
    @State var isBeat: Bool = false
    
    var body: some View {
        AwesomePro.Regular.lightbulbOn.image
            .size(80)
            .foregroundColor(isBeat ? .orange : .black)
        
    }
}

#Preview {
    InstantMetronomeView()
}
