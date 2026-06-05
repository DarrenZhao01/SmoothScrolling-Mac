//
//  SmoothScrollApp.swift
//  SmoothScroll
//
//  Created by Darren Zhao on 6/4/26.
//

import SwiftUI

@main
struct SmoothScrollApp: App {
    @State private var controller = SmoothScrollController()

    var body: some Scene {
        MenuBarExtra("SmoothScroll", systemImage: "arrow.up.and.down") {
            StatusMenuView(controller: controller)
        }

        WindowGroup {
            ContentView(controller: controller)
        }
    }
}
