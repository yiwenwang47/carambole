"""Patch the TEMPORARY perf-harness hooks into the app (run from repo root).

Copies PerfHarness.swift into carambole/Debug/ and adds: the RootView start
task, perfCommand navigation hooks (library/book/module list) and the
CB_PERF_* A/B switches. Revert afterwards with
`git checkout -- carambole && rm -rf carambole/Debug`.
"""
import pathlib
import shutil

ROOT = pathlib.Path("carambole")


def sub(path: str, old: str, new: str) -> None:
    p = ROOT / path
    s = p.read_text()
    assert s.count(old) == 1, (path, old)
    p.write_text(s.replace(old, new))


(ROOT / "Debug").mkdir(exist_ok=True)
shutil.copy(pathlib.Path(__file__).parent / "PerfHarness.swift", ROOT / "Debug" / "PerfHarness.swift")

sub("Views/RootView.swift", "        LibraryView()\n",
    "        LibraryView()\n            #if PERF_HARNESS\n            .task { PerfHarness.startIfRequested() }\n            #endif\n")
sub("Features/Library/LibraryView.swift", "                if ribbonLive {\n",
    "                if ribbonLive && !PerfFlags.noRibbon {\n")
sub("Features/Library/LibraryView.swift",
    "            .onChange(of: reduceMotion) { motion.reduceMotion = reduceMotion }\n",
    "            .onChange(of: reduceMotion) { motion.reduceMotion = reduceMotion }\n"
    "            .perfCommand(\"openBook\") { open() }\n"
    "            .perfCommand(\"openColors\") { ribbonLive = false; openColors = true }\n")
sub("DesignSystem/LoopWaveText.swift", "            if reduceMotion {\n                lines(fit, t: nil)",
    "            if reduceMotion || PerfFlags.staticWave {\n                lines(fit, t: nil)")
sub("Features/Settings/ColorSettingsView.swift",
    "                    ObjetStarView(mastered: 0.41, inProgress: 0.12, controller: star, palette: selected)\n",
    "                    Group {\n                        if PerfFlags.noColorStar { Color.clear } else {\n"
    "                            ObjetStarView(mastered: 0.41, inProgress: 0.12, controller: star, palette: selected)\n"
    "                        }\n                    }\n")
sub("Features/Book/BookView.swift",
    "        .navigationBarBackButtonHidden(true)\n    }\n\n    // MARK: - Derived",
    "        .navigationBarBackButtonHidden(true)\n        .perfCommand(\"openModules\") { openModules() }\n    }\n\n    // MARK: - Derived")
sub("Features/Book/ModuleListView.swift", "    @Environment(\\.dismiss) private var dismiss\n",
    "    @Environment(\\.dismiss) private var dismiss\n    @State private var perfOpen = false\n")
sub("Features/Book/ModuleListView.swift", "        .swipeToGoBack { dismiss() }\n",
    "        .swipeToGoBack { dismiss() }\n"
    "        .navigationDestination(isPresented: $perfOpen) {\n"
    "            if let m = modules.first { ModuleDetailView(module: m, viewModel: viewModel) }\n        }\n"
    "        .perfCommand(\"openModule\") { perfOpen = true }\n")
print("hooks applied")
