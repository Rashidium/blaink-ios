//
//  ClientRequest.swift
//  API
//
//  Created by Rashid Ramazanov on 10/19/22.
//  Copyright © 2022 Mobven. All rights reserved.
//

import Foundation

struct ClientRequest: Encodable {
    let clientId: String
    let sdkKey: String
    let device: Device
    struct Device: Encodable {
        let deviceId: String
        let deviceName: String
        let platform: String
        let language: String?
        let pushNotificationToken: String?
        let pushEnvironment: Blaink.PushEnvironment
    }
}

public extension Blaink {
    enum PushEnvironment: String, Encodable {
        case development, production
    }
}
