//
//  MusicInteractor.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 04/03/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Foundation

enum PlayingState { case  stopped, playing, paused }

protocol MusicInteractorType {
    var isFrontmost: Bool { get }
    
    var currentTrack: Track? { get }
    var soundVolume: Int? { get }
    var playerState: PlayingState? { get }
    var playerPosition: Double? { get }
    
    func nextTrack()
    func previousTrack()
    func playPause()
    func play()
    func pause()
}
