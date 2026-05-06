//
//  SongNavigationViewModelTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 5/1/26.
//

@testable import BeatClikr
import XCTest

@MainActor
final class SongNavigationViewModelTests: XCTestCase {
    // MARK: - Helpers

    private func makeSong(title: String = "Test", bpm: Double = 120) -> Song {
        Song(title: title, artist: "Artist", beatsPerMinute: bpm, beatsPerMeasure: 4, groove: .quarter)
    }

    private func makeMetronome() -> MetronomePlaybackViewModel {
        MetronomePlaybackViewModel()
    }

    // MARK: - Initial state

    func testInitialStateHasNilId() {
        let vm = SongNavigationViewModel()
        XCTAssertNil(vm.currentSongId)
    }

    // MARK: - playSong

    func testPlaySongStoresId() {
        let vm = SongNavigationViewModel()
        let song = makeSong(title: "A")
        let metronome = makeMetronome()
        vm.playSong(song, metronome: metronome)
        XCTAssertEqual(vm.currentSongId, song.id)
        metronome.stop()
    }

    func testPlaySongReplacesExistingId() {
        let vm = SongNavigationViewModel()
        let songA = makeSong(title: "A")
        let songB = makeSong(title: "B")
        let metronome = makeMetronome()
        vm.playSong(songA, metronome: metronome)
        vm.playSong(songB, metronome: metronome)
        XCTAssertEqual(vm.currentSongId, songB.id)
        metronome.stop()
    }

    // MARK: - currentIndex

    func testCurrentIndexNilWhenNoSongPlaying() {
        let vm = SongNavigationViewModel()
        let songs = [makeSong(title: "A"), makeSong(title: "B")]
        XCTAssertNil(vm.currentIndex(in: songs))
    }

    func testCurrentIndexFindsCorrectPosition() {
        let vm = SongNavigationViewModel()
        let songA = makeSong(title: "A")
        let songB = makeSong(title: "B")
        let songC = makeSong(title: "C")
        vm.currentSongId = songB.id
        XCTAssertEqual(vm.currentIndex(in: [songA, songB, songC]), 1)
    }

    func testCurrentIndexNilWhenSongAbsentFromList() {
        let vm = SongNavigationViewModel()
        let songA = makeSong(title: "A")
        let songB = makeSong(title: "B")
        vm.currentSongId = songA.id
        XCTAssertNil(vm.currentIndex(in: [songB]))
    }

    // MARK: - Index drift regression tests

    func testCurrentIndexStableAfterDeletionBeforeCurrent() {
        let vm = SongNavigationViewModel()
        let songA = makeSong(title: "A")
        let songB = makeSong(title: "B")
        let songC = makeSong(title: "C")
        vm.currentSongId = songB.id
        XCTAssertEqual(vm.currentIndex(in: [songA, songB, songC]), 1)
        // songA is deleted — array shifts left
        XCTAssertEqual(vm.currentIndex(in: [songB, songC]), 0,
                       "Index should follow the song's identity to its new position")
    }

    func testCurrentIndexStableAfterInsertionBeforeCurrent() {
        let vm = SongNavigationViewModel()
        let songA = makeSong(title: "A")
        let songB = makeSong(title: "B")
        let songNew = makeSong(title: "New")
        vm.currentSongId = songB.id
        XCTAssertEqual(vm.currentIndex(in: [songA, songB]), 1)
        // A new song is inserted before B
        XCTAssertEqual(vm.currentIndex(in: [songNew, songA, songB]), 2,
                       "Index should follow the song's identity after insertion")
    }

    // MARK: - canGoNext

    func testCanGoNextFalseWhenNoCurrentSong() {
        let vm = SongNavigationViewModel()
        XCTAssertFalse(vm.canGoNext(items: [makeSong(), makeSong()]))
    }

    func testCanGoNextFalseAtLastSong() {
        let vm = SongNavigationViewModel()
        let songs = [makeSong(title: "A"), makeSong(title: "B")]
        vm.currentSongId = songs[1].id
        XCTAssertFalse(vm.canGoNext(items: songs))
    }

    func testCanGoNextTrueWhenNotAtEnd() {
        let vm = SongNavigationViewModel()
        let songs = [makeSong(title: "A"), makeSong(title: "B")]
        vm.currentSongId = songs[0].id
        XCTAssertTrue(vm.canGoNext(items: songs))
    }

    // MARK: - canGoPrevious

    func testCanGoPreviousFalseWhenNoCurrentSong() {
        let vm = SongNavigationViewModel()
        XCTAssertFalse(vm.canGoPrevious(items: [makeSong(), makeSong()]))
    }

    func testCanGoPreviousFalseAtFirstSong() {
        let vm = SongNavigationViewModel()
        let songs = [makeSong(title: "A"), makeSong(title: "B")]
        vm.currentSongId = songs[0].id
        XCTAssertFalse(vm.canGoPrevious(items: songs))
    }

    func testCanGoPreviousTrueWhenNotAtStart() {
        let vm = SongNavigationViewModel()
        let songs = [makeSong(title: "A"), makeSong(title: "B")]
        vm.currentSongId = songs[1].id
        XCTAssertTrue(vm.canGoPrevious(items: songs))
    }

    // MARK: - playNext / playPrevious

    func testPlayNextAdvancesToNextSong() {
        let vm = SongNavigationViewModel()
        let songA = makeSong(title: "A")
        let songB = makeSong(title: "B")
        let metronome = makeMetronome()
        vm.currentSongId = songA.id
        vm.playNext(items: [songA, songB], metronome: metronome)
        XCTAssertEqual(vm.currentSongId, songB.id)
        metronome.stop()
    }

    func testPlayNextIsNoOpAtLastSong() {
        let vm = SongNavigationViewModel()
        let songA = makeSong(title: "A")
        let songB = makeSong(title: "B")
        let metronome = makeMetronome()
        vm.currentSongId = songB.id
        vm.playNext(items: [songA, songB], metronome: metronome)
        XCTAssertEqual(vm.currentSongId, songB.id, "Should not advance past the last song")
        metronome.stop()
    }

    func testPlayPreviousGoesBack() {
        let vm = SongNavigationViewModel()
        let songA = makeSong(title: "A")
        let songB = makeSong(title: "B")
        let metronome = makeMetronome()
        vm.currentSongId = songB.id
        vm.playPrevious(items: [songA, songB], metronome: metronome)
        XCTAssertEqual(vm.currentSongId, songA.id)
        metronome.stop()
    }

    func testPlayPreviousIsNoOpAtFirstSong() {
        let vm = SongNavigationViewModel()
        let songA = makeSong(title: "A")
        let songB = makeSong(title: "B")
        let metronome = makeMetronome()
        vm.currentSongId = songA.id
        vm.playPrevious(items: [songA, songB], metronome: metronome)
        XCTAssertEqual(vm.currentSongId, songA.id, "Should not go before the first song")
        metronome.stop()
    }

    // MARK: - playOrResume

    func testPlayOrResumeStartsFirstSongWhenNoneSelected() {
        let vm = SongNavigationViewModel()
        let songA = makeSong(title: "A")
        let songB = makeSong(title: "B")
        let metronome = makeMetronome()
        vm.playOrResume(items: [songA, songB], metronome: metronome)
        XCTAssertEqual(vm.currentSongId, songA.id)
        metronome.stop()
    }

    func testPlayOrResumeRestartsCurrentSong() {
        let vm = SongNavigationViewModel()
        let songA = makeSong(title: "A")
        let songB = makeSong(title: "B")
        let metronome = makeMetronome()
        vm.currentSongId = songB.id
        vm.playOrResume(items: [songA, songB], metronome: metronome)
        XCTAssertEqual(vm.currentSongId, songB.id, "Should replay the current song")
        metronome.stop()
    }

    func testPlayOrResumeFallsBackToFirstWhenCurrentDeleted() {
        let vm = SongNavigationViewModel()
        let songA = makeSong(title: "A")
        let songB = makeSong(title: "B")
        let songC = makeSong(title: "C")
        let metronome = makeMetronome()
        vm.currentSongId = songA.id
        // songA was deleted from the list
        vm.playOrResume(items: [songB, songC], metronome: metronome)
        XCTAssertEqual(vm.currentSongId, songB.id,
                       "Should fall back to the first available song when the current song was deleted")
        metronome.stop()
    }

    // MARK: - currentSongTitle

    func testCurrentSongTitleNilWhenNoSongSelected() {
        let vm = SongNavigationViewModel()
        XCTAssertNil(vm.currentSongTitle(in: [makeSong(title: "A")]))
    }

    func testCurrentSongTitleReturnsCorrectTitle() {
        let vm = SongNavigationViewModel()
        let songA = makeSong(title: "Alpha")
        let songB = makeSong(title: "Beta")
        vm.currentSongId = songB.id
        XCTAssertEqual(vm.currentSongTitle(in: [songA, songB]), "Beta")
    }
}
