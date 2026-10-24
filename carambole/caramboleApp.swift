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
        // Before the silent star video plays: the default session would stop
        // the learner's music on launch.
        Speaker.useAmbientSession()
        #if DEBUG
        DrillEngine._selfTest()
        DrillView._selfTest()
        WaveText._selfTest()
        LoopWaveText._selfTest()
        Exercise._selfTest()
        StudyScheduler._selfTest()
        StudySettingsStore._selfTest()
        HistoryViewModel._selfTest()
        HistoryViewModel._selfTestRibbon()
        ProgressEstimate._selfTest()
        FSRS._selfTest()
        CalendarDays._selfTest()
        LearnLoop._selfTest()
        DrillLadder._selfTest()
        DataManager._selfTest()
        VocabBook._selfTest()
        VocabQueue._selfTest()
        VocabSwipeCard._selfTest()
        VocabPacing._selfTest()
        VocabPlacement._selfTest()
        BookCredits._selfTest()
        TokenPileScene._selfTest()
        StarVideoRenderer.runIfRequested()
        DemoSeed.runIfRequested()
        DemoRemote.start()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
