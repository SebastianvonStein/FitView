//
//  IndicatorSitup.swift
//  FitView
//
//  Created by Konstantin Freiherr von Stein on 12/12/24.
//

import SwiftUI

struct IndicatorSitup: View {
    
    @Binding var spacing: CGFloat
    @Binding var goingClose: Bool
    
    let circleSize: CGFloat = 280
    
    var body: some View {
        ZStack() {
            
            Group() {
                Circle()
                    .trim(from: 0.749 - ( 0.25 * spacing), to: 0.751 + ( 0.25 * spacing))
                    .stroke(Color.pink, style: StrokeStyle(lineWidth: goingClose ? ( 35 - ( spacing * 35 ) ) : ( 5 + ( spacing * 35 ) ), lineCap: .round))
                    .foregroundStyle(.pink)
                    .frame(width: circleSize, height: circleSize)
            }
            .offset(y: circleSize / 4)
            .opacity(!goingClose ? (spacing + 0.1) : abs((spacing - 1.1)))
            
            
        }
        .frame(height: circleSize / 2)
        //.background(.white.opacity(0.1))
        .padding(.top, 20)
        .overlay() {
            ZStack() {
                Image(systemName: !goingClose ? "arrow.left.and.line.vertical.and.arrow.right" : "arrow.right.and.line.vertical.and.arrow.left")
                    .font(.system(size: 80, weight: .black, design: .default))
                    .foregroundStyle(.pink)
                    .symbolEffect(.bounce, value: goingClose)
                
                Rectangle()
                    .foregroundStyle(.black.opacity(1))
                    .frame(width: 19, height: 100)
                    .opacity(0)
            }
            .offset(x: 0, y: 60)
        }
        .animation(.bouncy, value: goingClose)
    }
}

#Preview {
    IndicatorSitup(spacing: .constant(0.5), goingClose: .constant(true))
}
