//
//  Device.swift
//  API
//
//  Created by Rashid Ramazanov on 26.03.2023.
//

import Foundation
import SwiftUI

struct DeviceResponse: Decodable, Identifiable {
    var id: String?
    var deviceId: String?
    var name: String?
    var platform: String?
    var updatedA: Date?
    var createdAt: Date?
}
