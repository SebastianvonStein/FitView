//
//  Extensions.swift
//  FitView
//
//  Created by Konstantin Freiherr von Stein on 11/12/24.
//

import Foundation
import SwiftUI

struct PushupNumberViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentTransition(.numericText())
            .font(.system(size: 265, weight: .heavy, design: .default))
            .fontWidth(.compressed)
            .foregroundStyle(
                RadialGradient(colors: [.pink.opacity(1), .pink.opacity(0.7), .init(red: 0.1, green: 0.1, blue: 0.1, opacity: 1)], center: .bottom, startRadius: 30, endRadius: 400)
            )
            .shadow(color: .pink.opacity(0.3), radius: 35, x: 0, y: 12)
            
    }
}

extension View {
    /// Pushups Count Style
    func pushupsCount() -> some View {
        self.modifier(PushupNumberViewModifier())
    }
}

struct PushupNumberBlurViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentTransition(.numericText())
            .font(.system(size: 265, weight: .heavy, design: .default))
            .fontWidth(.compressed)
            .foregroundStyle(LinearGradient(colors: [.pink.opacity(0.6), .clear], startPoint: .bottom, endPoint: .top))
            .blur(radius: 14)
            
    }
}

extension View {
    /// Pushups Count Style
    func pushupsCountBlur() -> some View {
        self.modifier(PushupNumberBlurViewModifier())
    }
}



struct ButtonViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.plain)
            .font(.system(size: 60, weight: .heavy, design: .default))
            .fontWidth(.compressed)
            .foregroundStyle(
                RadialGradient(colors: [.pink.opacity(1), .pink.opacity(0.7), .init(red: 0.1, green: 0.1, blue: 0.1, opacity: 1)], center: .bottom, startRadius: 10, endRadius: 220)
            )
            .padding(.horizontal, 10)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 25).fill(.thinMaterial))
            
    }
}


extension View {
    /// Pushups Count Style
    func buttonModifier() -> some View {
        self.modifier(ButtonViewModifier())
    }
}





struct IconViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: 80, height: 80, alignment: .bottom)
            .zIndex(20)
            .scaleEffect(x: 0.35, y: 0.35, anchor: .bottom)
            .background(.white.opacity(0.2))
            .colorInvert()
            .colorMultiply(.gray.opacity(0.8))
            
    }
}


extension View {
    /// Pushups Count Style
    func iconModifier() -> some View {
        self.modifier(IconViewModifier())
    }
}

