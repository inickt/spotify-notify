//
//  iTunesInteractor.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 04/03/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import AppKit
import ScriptingBridge

final class iTunesInteractor: MusicInteractorType {
    private let itunes: iTunesApplication? = SBApplication(bundleIdentifier: SpotifyConstants.bundleIdentifier)
    
    var isFrontmost: Bool { return itunes?.frontmost ?? false }
    
    var currentTrack: Track? { return itunes?.currentTrack?.track }
    var soundVolume: Int? { return itunes?.soundVolume }
    var playerState: PlayingState? { return itunes?.playerState?.playingState }
    var playerPosition: Double? { return itunes?.playerPosition }
    
    func nextTrack() {
        itunes?.nextTrack?()
    }
    
    func previousTrack() {
        itunes?.previousTrack?()
    }
    
    func playPause() {
        itunes?.playpause?()
    }
    
    func play() {
        itunes?.playpause?()
    }
    
    func pause() {
        itunes?.pause?()
    }
}

extension iTunesEPlS {
    var playingState: PlayingState {
        switch self {
        case .stopped: return .stopped
        case .playing, .fastForwarding, .rewinding: return .playing
        case .paused: return .paused
        }
    }
}
