//
//  AdaptiveStack.swift
//  view that could be used to make an adaptive stack
//  lab11_Adaptive_omar
//
//  Created by Omar Abou Chaer on 2022-12-04.
//  Email: abouchae@sheridancollege.ca

import SwiftUI

struct AdaptiveStack<Content: View>: View {
    
    // properties
    @Environment(\.verticalSizeClass) var vSizeClass
    var hAlignment: HorizontalAlignment // for VStack
    var vAlignment: VerticalAlignment // for HStack
    var spacing: CGFloat // gap between views
    var content: () -> Content // viewBuilder to create the content
    
    init(hAlignment: HorizontalAlignment = .center,
         vAlignment: VerticalAlignment = .center,
         spacing: CGFloat = 10,
         @ViewBuilder content: @escaping () -> Content) {
        self.hAlignment = hAlignment
        self.vAlignment = vAlignment
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        
        // portrait mode wCompact x hRegular
        if vSizeClass == .regular {
            VStack(alignment: hAlignment, spacing: spacing, content: content)
        }
        // landscape mode wAny x hCompact
        else {
            HStack(alignment: vAlignment, spacing: spacing, content: content)
        }
    }
}
