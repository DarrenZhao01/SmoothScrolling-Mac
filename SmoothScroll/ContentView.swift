//
//  ContentView.swift
//  SmoothScroll
//
//  Created by Darren Zhao on 6/4/26.
//

import SwiftUI

struct ContentView: View {
    @Bindable var controller: SmoothScrollController

    var body: some View {
        Form {
            StatusSectionView(controller: controller)
            ScrollingSectionView(controller: controller)
        }
        .padding()
        .formStyle(.grouped)
        .frame(width: 440)
        .onAppear(perform: controller.startIfNeeded)
    }
}

#Preview {
    ContentView(controller: SmoothScrollController())
}
