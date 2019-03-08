//
//  PreferencesView.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Cocoa
import KeyHolder
import Magnet

final class RecordingView: RecordView { }

extension NSNotification.Name {
	static let userPreferencesDidChangeStartup = NSNotification.Name(rawValue: "userPreferencesDidChangeStartup.notification")
	static let userPreferencesDidChangeIcon = NSNotification.Name(rawValue: "userPreferencesDidChangeIcon.notification")
}

final class PreferencesView: NSVisualEffectView {
	@IBOutlet weak var notificationsCheck: NSButton!
	@IBOutlet weak var notificationsPlayPauseCheck: NSButton!
	@IBOutlet weak var notificationsSoundCheck: NSButton!
	@IBOutlet weak var notificationsSpotifyFocusCheck: NSButton!
	
	@IBOutlet weak var startOnLoginCheck: NSButton!
	@IBOutlet weak var showAlbumArtCheck: NSButton!
	@IBOutlet weak var roundAlbumArtCheck: NSButton!
	@IBOutlet weak var showSpotifyIconCheck: NSButton!
    @IBOutlet weak var showSongProgressCheck: NSButton!
    
    @IBOutlet weak var notificationLengthField: NSTextField!
    @IBOutlet weak var notificationLengthChanger: NSStepper!
    
    @IBOutlet weak var menuIconCheck: NSButton!
	@IBOutlet weak var menuIconPopUpButton: NSPopUpButton!
	
	@IBOutlet weak var recordShortcutView: RecordingView! {
		didSet {
			recordShortcutView.cornerRadius = 14
			recordShortcutView.tintColor = .darkGray
		}
	}
	
	@IBOutlet weak var sourceButton: NSButton!
	@IBOutlet weak var homeButton: NSButton!
	@IBOutlet weak var quitButton: NSButton!
	
	private var preferences = UserPreferences()
	private let shortcutsInteractor = ShortcutsInteractor()
	
	override func viewWillDraw() {
		super.viewWillDraw()
		checkAvailability()
		setup()
        checkCompability()
		setupTargets()
	}
	
	private func checkAvailability() {
		if !SystemPreferences.isContentImagePropertyAvailable {
			showAlbumArtCheck.isEnabled = false
			roundAlbumArtCheck.isEnabled = false
		}
	}
    
    private func checkCompability() {
        notificationsPlayPauseCheck.isEnabled = preferences.notificationsEnabled
        notificationsSoundCheck.isEnabled = preferences.notificationsEnabled
        notificationsSpotifyFocusCheck.isEnabled = preferences.notificationsEnabled
        showAlbumArtCheck.isEnabled = preferences.notificationsEnabled
        showSpotifyIconCheck.isEnabled = preferences.notificationsEnabled
        roundAlbumArtCheck.isEnabled = preferences.notificationsEnabled && preferences.showAlbumArt
        showSongProgressCheck.isEnabled = preferences.notificationsEnabled
        menuIconPopUpButton.isEnabled = preferences.menuIcon != .none
    }
	
	private func setup() {
		notificationsCheck.isSelected = preferences.notificationsEnabled
		notificationsPlayPauseCheck.isSelected = preferences.notificationsPlayPause
		notificationsSoundCheck.isSelected = preferences.notificationsSound
		notificationsSpotifyFocusCheck.isSelected = preferences.notificationsDisableOnFocus
		
		startOnLoginCheck.isSelected = preferences.startOnLogin
		showAlbumArtCheck.isSelected = preferences.showAlbumArt
		roundAlbumArtCheck.isSelected = preferences.roundAlbumArt
		showSpotifyIconCheck.isSelected = preferences.showSpotifyIcon
        showSongProgressCheck.isSelected = preferences.showSongProgress
		
        notificationLengthField.doubleValue = Double(preferences.notificationsLength)
        notificationLengthChanger.integerValue = preferences.notificationsLength
        
        menuIconCheck.isSelected = preferences.menuIcon != .none
        if preferences.menuIcon != .none { menuIconPopUpButton.selectItem(at: preferences.menuIcon.rawValue) }
		
		recordShortcutView.keyCombo = preferences.shortcut
	}
	
	private func setupTargets() {
		recordShortcutView.delegate = self
	}
    
    @IBAction func notificationsCheckTapped(sender: NSButton) {
		preferences.notificationsEnabled = sender.isSelected
        checkCompability()
	}
	
	@IBAction func notificationsPlayPauseCheckTapped(sender: NSButton) {
		preferences.notificationsPlayPause = sender.isSelected
	}
	
	@IBAction func notificationsSoundCheckTapped(sender: NSButton) {
		preferences.notificationsSound = sender.isSelected
	}
	
	@IBAction func notificationsSpotifyFocusCheckTapped(sender: NSButton) {
		preferences.notificationsDisableOnFocus = sender.isSelected
	}
	
	@IBAction func startOnLoginCheckTapped(sender: NSButton) {
		preferences.startOnLogin = sender.isSelected
		DistributedNotificationCenter.default().post(name: .userPreferencesDidChangeStartup, object: nil)
	}
	
	@IBAction func showAlbumArtCheckTapped(sender: NSButton) {
		preferences.showAlbumArt = sender.isSelected
        checkCompability()
	}
	
	@IBAction func roundAlbumArtCheckTapped(sender: NSButton) {
		preferences.roundAlbumArt = sender.isSelected
	}
	
	@IBAction func showSpotifyIconCheckTapped(sender: NSButton) {
		preferences.showSpotifyIcon = sender.isSelected
	}
    
    @IBAction func showSongProgressCheckTapped(sender: NSButton) {
        preferences.showSongProgress = sender.isSelected
    }
    
    @IBAction func notificationLengthFieldChanged(sender: NSTextField) {
        guard sender.doubleValue >= 1.0 else {
            notificationLengthField.integerValue = 1
            preferences.notificationsLength = 1
            notificationLengthField.doubleValue = 1.0
            return
        }
        
        preferences.notificationsLength = Int(sender.doubleValue)
        notificationLengthChanger.integerValue = Int(sender.doubleValue)
    }
    
    @IBAction func notificationLengthChangerTapped(sender: NSStepper) {
        guard sender.integerValue >= 1 else {
            notificationLengthField.integerValue = 1
            preferences.notificationsLength = 1
            notificationLengthField.doubleValue = 1
            return
        }
        
        preferences.notificationsLength = Int(sender.integerValue)
        notificationLengthField.doubleValue = Double(sender.integerValue)
    }
	
    @IBAction func menuIconCheckTapped(sender: NSButton) {
        if sender.isSelected {
            preferences.menuIcon = StatusBarIcon(value: menuIconPopUpButton.indexOfSelectedItem)
        } else {
            preferences.menuIcon = .none
        }

        DistributedNotificationCenter.default().post(name: .userPreferencesDidChangeIcon, object: nil)
    }
    
	@IBAction func menuIconPopUpButtonChanged(sender: NSPopUpButton) {
		preferences.menuIcon = StatusBarIcon(value: sender.indexOfSelectedItem)
		DistributedNotificationCenter.default().post(name: .userPreferencesDidChangeIcon, object: nil)
	}
	
	@IBAction func sourceButtonTapped(sender: NSButton) {
		NSWorkspace.shared.open(NahiveConstraints.repo)
	}
	
	@IBAction func homeButtonTapped(sender: NSButton) {
		NSWorkspace.shared.open(NahiveConstraints.homepage)
	}
	
	@IBAction func quitButtonTapped(sender: NSButton) {
        NSApplication.shared.terminate(sender)
	}
}

extension PreferencesView: RecordViewDelegate {
	func recordViewShouldBeginRecording(_ recordView: RecordView) -> Bool {
		return true
	}
	
	func recordView(_ recordView: RecordView, canRecordKeyCombo keyCombo: KeyCombo) -> Bool {
		return true
	}
	
	func recordViewDidClearShortcut(_ recordView: RecordView) {
		shortcutsInteractor.unregister()
		preferences.shortcut = nil
	}
	
	func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo) {
		shortcutsInteractor.register(combo: keyCombo)
		preferences.shortcut = keyCombo
	}
	
	func recordViewDidEndRecording(_ recordView: RecordView) {
		// nothing
	}
}
