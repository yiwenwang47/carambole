//
//  caramboleApp.swift
//  carambole
//
//  Created by Yiwen Wang on 6/4/25.
//

import SwiftUI

@main
struct caramboleApp: App {
    init() {
        #if DEBUG
        DrillEngine._selfTest()
        DrillView._selfTest()
        Exercise._selfTest()
        SRSScheduler._selfTest()
        StudyScheduler._selfTest()
        StudySettingsStore._selfTest()
        HistoryViewModel._selfTest()
        ProgressEstimate._selfTest()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
