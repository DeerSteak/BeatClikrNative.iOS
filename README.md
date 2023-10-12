# BeatClikrNative.iOS
BeatClikr's reimplementation for iOS 17 with SwiftUI, SwiftData, and CloudKit. 

Note: This project relies on a series of .WAV files that are not in git. You will need to add these yourself:

- WAV files go with their correct names in Resources/Sounds
- See Constants/FileConstants for the correct WAV filenames

The WAV files are proprietary and I recorded them myself. You're free to use this code, but you'll need your own media files. :D 

## About Keeping Time

The Swift Timer class is a best-effort sort of thing, so clicks can drift ahead or behind,
eventually getting out of sync with any other instruments like a MIDI keyboard. That would
result in delays not being on the beat. The Timer class is how the .NET MAUI version of
this application works, and it's not ideal. 

The better solution is using Grand Central Dispatch. We're not doing anything fancy with concurrency, but instead calculating the delay to the next beat in excruciatingly small fractions of a second - 1/50 * the milliseconds of a subdivision. Let's look at an example.

Tempo: 100 bpm
Subdivisions per Beat: 2 (Eighth notes)
Milliseconds per subdivision: 50

In our MetronomeTimer class, the subdivisionCheckInterval is then calculated to be 1 millisecond. So every millisecond GCD checks to see if it's time to fire the next subdivision, with a 10% tolerance per Apple's recommendation. 

Then using that interval, the time to the next subdivision is calculated. When the timer has elapsed (within 0.9 to 1.1 milliseconds, based on the tolerance), the timerElapsed event fires. The MetronomePlaybackViewModel is the delegate that handles UI updates, plays sound, flashes the flashlight, and vibrates the device. 

The MetronomePlaybackViewModel is an EnvironmentObject supplied by the beatclikrApp class, so every screen that has a metronome shares the same instance. This ensures we don't get unkillable instances running in the background or something. 

## About Audio Playback

We're using AudioKit for sound playback. It's got a nice implementation of the AVAudioUnitSampler (same technology as Logic's EXS24 sampler), and the AudioPlayerService just loads the WAV files into it, and handles triggering the correct notes based on user preferences. 

The other time keeping features are all synced up with this, so playing a beat or a subdivision will result in vibration using the UIImpactFeedbackGenerator, a flashlight using AVCaptureDevice torchMode, and changing the icon on the screen. 

## About the Song Library

The song library and playback playlist are built with SwiftData, hence the iOS 17 requirement. By the time I expect this to be in the AppStore, iOS 17 should be on the majority of devices. I don't think this will pose a big hurdle for too many users. 

The larger goal is to sync the library across devices without a cloud infrastructure, and iCloud / CloudKit is the perfect solution for that. To be implemented at a later date. 
