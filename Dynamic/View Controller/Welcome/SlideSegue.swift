//
//  SlideSegue.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 9/25/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import SwiftUI

class SlideSegue: NSStoryboardSegue, NSViewControllerPresentationAnimator {
    override func perform() { }
    func animatePresentation(of viewController: NSViewController, from fromViewController: NSViewController) { }
    func animateDismissal(of viewController: NSViewController, from fromViewController: NSViewController) { }
}

struct OnboardingStepCard<Actions: View>: View {
    let eyebrow: String
    let title: String
    let message: String
    let symbolName: String
    @ViewBuilder var actions: Actions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Label(eyebrow.uppercased(), systemImage: symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
                
                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
            
            actions
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.18))
        )
        .shadow(color: .black.opacity(0.12), radius: 24, y: 20)
    }
}

struct OnboardingBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.97, blue: 1.0),
                    Color(red: 0.90, green: 0.95, blue: 0.97),
                    Color(red: 0.96, green: 0.93, blue: 0.89)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 320, height: 320)
                .offset(x: -220, y: -180)
                .blur(radius: 20)
            Circle()
                .fill(Color(red: 0.76, green: 0.87, blue: 0.98).opacity(0.45))
                .frame(width: 360, height: 360)
                .offset(x: 260, y: 180)
                .blur(radius: 28)
        }
        .ignoresSafeArea()
    }
}
