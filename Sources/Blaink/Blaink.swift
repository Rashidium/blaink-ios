//
//  Blaink.swift
//  Blaink
//
//  Created by Raşid Ramazanov on 23.08.2025.
//

import Foundation
import UIKit
import UserNotifications

@MainActor public final class Blaink: NSObject {
    public weak var delegate: BlainkDelegate?

    var sdkKey: String = ""
    var environment: PushEnvironment = .production

    override public init() {
        super.init()
    }

    public func setup(sdkKey: String, environment: PushEnvironment = .production, isDebugLogsEnabled: Bool = false) {
        self.sdkKey = sdkKey
        self.environment = environment
        PinnedURLSession.shared.isDebugLogsEnabled = isDebugLogsEnabled
        UNUserNotificationCenter.current().delegate = self
        let cat = UNNotificationCategory(
            identifier: "blaink_category",
            actions: [], // custom action buttons
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([cat])

        let request = ClientRequest(
            clientId: Keychain.shared.blainkClientId,
            sdkKey: sdkKey,
            device: ClientRequest.Device(
                deviceId: Keychain.shared.blainkDeviceId,
                deviceName: UIDevice.current.name,
                platform: "iOS",
                language: Locale.current.language.languageCode?.identifier,
                pushNotificationToken: Keychain.shared.pushNotificationToken,
                pushEnvironment: environment
            )
        )
        Task {
            let response = await API.AUTH.initSdk(request: request).fetch(responseModel: ClientResponse.self)
            switch response {
            case let .success(client):
                UserSession.shared.accessToken = client.accessToken
                UserSession.shared.refreshToken = client.refreshToken
                delegate?.didRegisterForBlainkNotifications(blainkUserId: client.id)
                if let token = Keychain.shared.pushNotificationToken {
                    submitAPNSToken(token)
                }
            case let .failure(failure):
                print(failure)
            }
        }
    }

    public func registerForRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        Keychain.shared.pushNotificationToken = token
        if UserSession.shared.accessToken != nil, !token.isEmpty {
            submitAPNSToken(token)
        }
    }

    func submitAPNSToken(_ token: String) {
        Task {
            _ = await API.AUTH
                .update(request: UpdateUserRequest(pushNotificationToken: token, pushEnvironment: environment))
                .fetch(responseModel: EmptyModel.self)
        }
    }

    public func didReceive(_ request: UNNotificationRequest) {
        guard let apnsID = getAPNSId(in: request) else { return }
        Task {
            let apnsRequest = APNSNotificationRequest(id: apnsID, action: "delivered")
            _ = await API.APNS.updateNotification(request: apnsRequest).fetch(responseModel: EmptyModel.self)
        }
    }
}

extension Blaink: @preconcurrency UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let apnsID = getAPNSId(in: response.notification) else { return }
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            let payload = response.notification.request.content.userInfo
            delegate?.didReceiveNotification(payload)
            let apnsRequest = APNSNotificationRequest(id: apnsID, action: "open")
            _ = await API.APNS.updateNotification(request: apnsRequest).fetch(responseModel: EmptyModel.self)
        case UNNotificationDismissActionIdentifier:
            let apnsRequest = APNSNotificationRequest(id: apnsID, action: "dismiss")
            _ = await API.APNS.updateNotification(request: apnsRequest).fetch(responseModel: EmptyModel.self)
        default:
            let apnsRequest = APNSNotificationRequest(id: apnsID, action: response.actionIdentifier)
            _ = await API.APNS.updateNotification(request: apnsRequest).fetch(responseModel: EmptyModel.self)
        }
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if let apnsID = getAPNSId(in: notification) {
            let apnsRequest = APNSNotificationRequest(id: apnsID, action: "delivered")
            _ = await API.APNS.updateNotification(request: apnsRequest).fetch(responseModel: EmptyModel.self)
        }
        return [.banner, .sound]
    }

    private func getAPNSId(in notification: UNNotification) -> UUID? {
        getAPNSId(in: notification.request)
    }

    private func getAPNSId(in request: UNNotificationRequest) -> UUID? {
        guard let idString = request.content.userInfo["notificationID"] as? String,
              let id = UUID(uuidString: idString) else {
            return nil
        }
        return id
    }
}

public protocol BlainkDelegate: AnyObject {
    func didReceiveNotification(_ notification: [AnyHashable: Any])
    func didRegisterForBlainkNotifications(blainkUserId: String)
}
