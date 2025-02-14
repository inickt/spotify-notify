//
//  AppDelegate.swift
//  NotifySpotify
//
//  Created by Szymon Maślanka on 15/03/16.
//  Copyright © 2016 Szymon Maślanka. All rights reserved.
//

import Cocoa
import LaunchAtLogin
import ScriptingBridge

#if canImport(UserNotifications)
import UserNotifications
#endif

extension Notification.Name {
	static let killLauncher = Notification.Name("kill.launcher.notification")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	@IBOutlet weak var preferencesWindow: NSWindow!
	@IBOutlet weak var statusMenu: NSMenu!
	@IBOutlet weak var statusStatus: NSMenuItem!
	@IBOutlet weak var statusPreferences: NSMenuItem!
	@IBOutlet weak var statusQuit: NSMenuItem!
	
	fileprivate var preferences = UserPreferences()
	fileprivate let notificationsInteractor = NotificationsInteractor()
	fileprivate let shortcutsInteractor = ShortcutsInteractor()
	fileprivate let spotifyInteractor = SpotifyInteractor()
	var statusBar: NSStatusItem!

    /// Used to avoid opening the preferences when a notification is clicked
    private var shouldIgnoreNextReopen = false

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		setup()
        updateStatus()
	}
	
	func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag && !shouldIgnoreNextReopen {
            showPreferences()
        }

        shouldIgnoreNextReopen = false
		return true
	}
}

// MARK: setup functions

extension AppDelegate {
	fileprivate func setup() {
		setupObservers()
		setupMenuBarIcon()
		setupStartup()
		setupTargets()
        setupFirstRun()
		setupShortcuts()
		setupUserNotifications()
	}
	
	private func setupObservers() {
		let center = DistributedNotificationCenter.default()
		
		center.addObserver(self, selector: #selector(playbackStateChanged),
						   name: NSNotification.Name(rawValue: SpotifyConstants.notificationPlaybackChange),
						   object: nil, suspensionBehavior: .deliverImmediately)
		
		center.addObserver(self, selector: #selector(setupStartup),
						   name: .userPreferencesDidChangeStartup, object: nil)
		
		center.addObserver(self, selector: #selector(setupMenuBarIcon),
						   name: .userPreferencesDidChangeIcon, object: nil)
		
		NSUserNotificationCenter.default.delegate = self
	}
	
	@objc private func setupMenuBarIcon() {
		if preferences.menuIcon == .none {
			statusBar = nil
			return
		}

		statusBar = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
		statusBar.menu = statusMenu

		var image = #imageLiteral(resourceName: "IconStatusBarColor")
		if preferences.menuIcon == .monochromatic {
			image = #imageLiteral(resourceName: "IconStatusBarBlack")
			image.isTemplate = true
		}

		statusBar.button!.image = image
	}

	@objc private func setupStartup() {
        LaunchAtLogin.isEnabled = preferences.startOnLogin
	}
	
	private func setupTargets() {
		statusPreferences.action = #selector(showPreferences)
		statusQuit.action = #selector(NSApplication.terminate(_:))
	}
    
    private func setupFirstRun() {
        guard !preferences.isNotFirstRun else { return }

        preferences.isNotFirstRun = true
        preferences.notificationsEnabled = true
        preferences.notificationsPlayPause = true
        preferences.notificationsSound = false
        preferences.notificationsDisableOnFocus = true
        preferences.notificationsLength = 5
        preferences.startOnLogin = false
        preferences.showAlbumArt = true
        preferences.roundAlbumArt = false
        preferences.showSpotifyIcon = true
        preferences.showSongProgress = false
        preferences.menuIcon = .default
    }
	
	fileprivate func setupShortcuts() {
		guard let shortcut = preferences.shortcut else { return }
		shortcutsInteractor.register(combo: shortcut)
	}

    /// Setup user notifications using UserNotifications framework
    private func setupUserNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self

        // Check notification authorisation first
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if let error = error {
                print("Notification authorisation was denied: \(error)")
            }
        }

        setNotificationCategories()
    }

    /// Add Skip and Close buttons to the notification
    private func setNotificationCategories() {
        let skip = UNNotificationAction(identifier: NotificationIdentifier.skip, title: "Skip")

        let category = UNNotificationCategory(identifier: NotificationIdentifier.category,
                                              actions: [skip],
                                              intentIdentifiers: [],
                                              options: [])

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

	@objc fileprivate func showPreferences() {
		NSApp.activate(ignoringOtherApps: true)
		preferencesWindow.makeKeyAndOrderFront(nil)
	}
	
	@objc fileprivate func playbackStateChanged(_ notification: Notification) {
        // guard against reopening spotify on closing
        guard notification.userInfo?["Player State"] as? String != "Stopped" else { return }
        
        notificationsInteractor.showNotification()
		updateStatus()
	}
	
	@objc func shortcutKeyTapped() {
        notificationsInteractor.showNotification(force: true)
	}
	
	private func updateStatus() {
        guard let state = spotifyInteractor.playerState else {
            statusStatus.title = "Status: Unavailable"
            return
        }
        
        switch state {
		case .playing:
			statusStatus.title = "Status: Playing"
		case .paused:
			statusStatus.title = "Status: Paused"
		case .stopped:
			statusStatus.title = "Status: Stopped"
        default:
            statusStatus.title = "Status: Unknown"
		}
	}
}

// MARK: notification delegates
extension AppDelegate: NSUserNotificationCenterDelegate {
	func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {
		// nothing
	}
	
	func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        shouldIgnoreNextReopen = true

        let action = notification.activationType == .actionButtonClicked ? NotificationIdentifier.skip : ""
        notificationsInteractor.handle(action: action)
	}
	
	func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
		return true
	}
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Force notifications to be shown, even if SpotifyNotify is in the foreground
        completionHandler([.alert, .sound])
    }

    /// Handle the action buttons
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        shouldIgnoreNextReopen = true

        notificationsInteractor.handle(action: response.actionIdentifier)
        completionHandler()
    }
}
