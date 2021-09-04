//  NotificationsInteractor.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Cocoa
import ScriptingBridge

#if canImport(UserNotifications)
import UserNotifications
#endif

final class NotificationsInteractor {
	
	private let preferences = UserPreferences()
	private let spotifyInteractor = SpotifyInteractor()
	
	private var previousTrack: Track?
	private var currentTrack: Track?

	// To avoid removing newer notifications early
	private var currentNotification: UInt = 0
	
    func showNotification(force: Bool = false) {
        previousTrack = currentTrack
        currentTrack  = spotifyInteractor.currentTrack

        guard let currentTrack = currentTrack else { return }

        guard force || shouldShow() else { return }

        // Create and deliver notifications
        let viewModel = NotificationViewModel(track: currentTrack)
		createNotification(using: viewModel)
	}

    /// Called by notification delegate
    func handle(action: String) {
        switch action {
        case NotificationIdentifier.skip:
            spotifyInteractor.nextTrack()
        default:
            spotifyInteractor.activate()
        }
    }

    private func shouldShow() -> Bool {
        guard preferences.notificationsEnabled else { return false }

        if preferences.notificationsDisableOnFocus && spotifyInteractor.isFrontmost { return false }

        if !preferences.notificationsPlayPause && currentTrack == previousTrack { return false }

        guard spotifyInteractor.playerState == .some(.playing) else { return false }

        return true
    }

    private func createNotification(using viewModel: NotificationViewModel) {
        let notification = UNMutableNotificationContent()

        notification.title = viewModel.title
        notification.subtitle = viewModel.subtitle
        notification.body = viewModel.body
        notification.categoryIdentifier = NotificationIdentifier.category

        // decide whether to add sound
        if preferences.notificationsSound {
            notification.sound = .default
        }

        if viewModel.shouldShowArtwork {
            addArtworkAndDeliver(to: notification, using: viewModel)
        } else {
            deliverNotification(identifier: viewModel.identifier, content: notification)
        }
    }

    private func addArtworkAndDeliver(to notification: UNMutableNotificationContent, using viewModel: NotificationViewModel) {
        guard viewModel.shouldShowArtwork else { return }

        viewModel.artworkURL?.asyncImage { art in
            // Create a mutable copy of the downloaded artwork
            var artwork = art

            // If user wants round album art, then round the image
            if self.preferences.roundAlbumArt {
                artwork = art?.applyCircularMask()
            }

            // Save the artwork to the temporary directory
            guard let url = artwork?.saveToTemporaryDirectory(withName: "artwork") else { return }

            // Add the attachment to the notification
            do {
                let attachment = try UNNotificationAttachment(identifier: "artwork", url: url)
                notification.attachments = [attachment]
            } catch {
                print("Error creating attachment: " + error.localizedDescription)
            }

            // remove previous notification and replace it with one with image
            DispatchQueue.main.async {
                self.deliverNotification(identifier: viewModel.identifier, content: notification)
            }
        }
    }

    /// Deliver notifications using `UNUserNotificationCenter`
    private func deliverNotification(identifier: String, content: UNMutableNotificationContent) {
        // Create a request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        let notificationCenter = UNUserNotificationCenter.current()

        // Remove delivered notifications
        notificationCenter.removeAllDeliveredNotifications()

        // Deliver current notification
        notificationCenter.add(request)

		currentNotification += 1
		let notificationId = currentNotification

        // remove after userset number of seconds if not taken action
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(preferences.notificationsLength)) {
			guard notificationId == self.currentNotification else { return }
            notificationCenter.removeAllDeliveredNotifications()
        }
    }
}
