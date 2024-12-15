//
//  Count.swift
//  FitView
//
//  Created by Konstantin Freiherr von Stein on 12/12/24.
//

import SwiftUI

struct Count: View {
    
    @Binding var situpCount: Int
    @Binding var doingSitups: Bool
    
    
    var body: some View {
        
        
        
        ZStack{
            ZStack{
                Text("\(situpCount)")
                    .pushupsCount()
                
                Text("\(situpCount)")
                    .pushupsCountBlur()
            }
            .opacity(doingSitups ? 1 : 0)
            
        }
        .geometryGroup()
        .animation(.snappy(duration: 0.6), value: situpCount)
        .animation(.snappy(duration: 0.6), value: doingSitups)
        .padding(50)
        .drawingGroup()
    }
}

#Preview {
    Count(situpCount: .constant(2), doingSitups: .constant(true))
}
