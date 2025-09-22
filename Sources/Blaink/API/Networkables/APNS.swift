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
}
