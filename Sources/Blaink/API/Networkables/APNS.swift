import Foundation

extension API {
    enum APNS: Networkable {
        case updateNotification(request: APNSNotificationRequest)

        func request() async -> URLRequest {
            switch self {
            case let .updateNotification(request):
                await put(body: request, path: "api/v1/client/updateNotification")
            }
        }
    }
}

struct APNSNotificationRequest: Encodable {
    let id: UUID
    let action: String
    let deviceInfo: String?

    init(id: UUID, action: String, deviceInfo: String? = nil) {
        self.id = id
        self.action = action
        self.deviceInfo = deviceInfo
    }
}
