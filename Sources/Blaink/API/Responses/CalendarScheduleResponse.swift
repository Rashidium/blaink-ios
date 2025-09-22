import Foundation

struct CalendarScheduleResponse: Codable {
    let schedule: [ScheduleItem]

    init(schedule: [ScheduleItem]) {
        self.schedule = schedule
    }
}

extension CalendarScheduleResponse {
    struct ScheduleItem: Codable {
        let weekday: Int
        let hour: Int
        let minute: Int
        let utcDifference: Int
        let duration: Int

        init(weekday: Int, hour: Int, minute: Int, utcDifference: Int, duration: Int) {
            self.weekday = weekday
            self.hour = hour
            self.minute = minute
            self.utcDifference = utcDifference
            self.duration = duration
        }
    }
}
