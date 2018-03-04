//
//  Constants.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Foundation

struct SpotifyConstants {
	static let applicationName = "Spotify"
	static let bundleIdentifier = "com.spotify.client"
	
	static let notificationPlaybackChange = bundleIdentifier + ".PlaybackStateChanged"
}

struct iTunesConstants {
    static let applicationName = "iTunes"
    static let bundleIdentifier = "com.apple.iTunes"
    
    static let notificationPlaybackChange = bundleIdentifier + ".playerInfo"
}

struct NahiveConstraints {
	static let homepage = "https://nahive.github.io".url!
	static let repo = "https://github.com/nahive/spotify-notify".url!
}

struct AppConstants {
	static let bundleIdentifier = "io.nahive.SpotifyNotify"
}
