//
//  NowSimpleApp.swift
//  NowSimple
//
//  Created by hanklee on 4/2/26.
//

import SwiftUI
import NowCore
import NowHybrid

@main
struct NowSimpleApp: App {
    init() {
        NowCore.initialize(context: .live)
        #if DEBUG
        NowHybrid.initialize(config: .init(isInspectable: true))
        #else
        NowHybrid.initialize()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
