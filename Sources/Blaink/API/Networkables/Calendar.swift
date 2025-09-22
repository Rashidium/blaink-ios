import Foundation

extension API {
    enum Calendar: Networkable {
        case schedule(request: ScheduleLessonRequest)
        case getSchedule

        func request() async -> URLRequest {
            switch self {
            case let .schedule(request):
                await post(body: request, path: "api/v1/schedule")
            case .getSchedule:
                await get(path: "api/v1/schedule")
            }
        }
    }
}
