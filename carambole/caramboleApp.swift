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
        AppFonts.register()
        #if DEBUG
        DrillEngine._selfTest()
        DrillView._selfTest()
        WaveText._selfTest()
        LoopWaveText._selfTest()
        TickerLine._selfTest()
        Exercise._selfTest()
        StudyScheduler._selfTest()
        StudySettingsStore._selfTest()
        HistoryViewModel._selfTest()
        HistoryViewModel._selfTestRibbon()
        LibraryRibbonGeometry._selfTest()
        ProgressEstimate._selfTest()
        FSRS._selfTest()
        CalendarDays._selfTest()
        LearnLoop._selfTest()
        DataManager._selfTest()
        StarVideoRenderer.runIfRequested()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
