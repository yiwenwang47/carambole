# Star loops

The book home and the colour page show the 01 Objet star as a pre-rendered
HEVC-with-alpha loop (`carambole/Resources/StarVideos/star_<palette>.mov`),
not a live RealityKit scene. A new RealityView cost ~100 ms on the main thread
at every push; a video layer on an already-loaded player shows at once. The
orbit ring (live progress) is drawn in 2D by `StarLoopView`.

Playback keeps one `AVPlayerItem` per palette and seeks that item to frame zero
at the end. The layer retains its last frame during the seek. A decoded
first-frame image sits above the player layer only until it reports
`isReadyForDisplay`; the image is then hidden. A still beneath the transparent
video shows through the moving star and must not be used.
The book reveals the orbit and star together once either the decoded first
frame or the video is visible. The progress bead keeps its front/back depth
relative to the star; the tube is clipped where it crosses a rear bead.

Regenerate after changing the star mesh, its materials, the lights or a
palette's star colour:

1. Build a **Debug** build and run it in a simulator (or a device you are
   allowed to use) with `CB_RENDER_STAR=1` in the environment, e.g.
   `SIMCTL_CHILD_CB_RENDER_STAR=1 xcrun simctl launch <sim> wen.carambole`.
2. Wait for `STAR VIDEOS DONE` in the log (`StarVideo` category).
3. Copy `Documents/star_*.mov` out of the app container
   (`xcrun simctl get_app_container <sim> wen.carambole data`) into
   `carambole/Resources/StarVideos/`.

Loop facts (`StarVideoGeometry`): 524 frames at 60 fps = half a turn at the
old rest spin (the star is mirror- and front/back-symmetric, so π loops
seamlessly), 900 px square covering 2 world units around the star.

Note: the committed loops were rendered on the iPhone 18 Pro GPU. A
simulator render uses the Mac GPU; compare a frame against the old ones
before replacing them.
