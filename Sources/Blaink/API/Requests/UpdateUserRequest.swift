//
//  UpdateUserRequest.swift
//  API
//
//  Created by Rashid Ramazanov on 25/03/25.
//  Copyright © 2022 Mobven. All rights reserved.
//

import Foundation

struct UpdateUserRequest: Encodable {
    let pushNotificationToken: String
    let pushEnvironment: Blaink.PushEnvironment
}
