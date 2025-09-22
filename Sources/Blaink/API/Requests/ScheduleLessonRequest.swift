import Foundation

struct TimeSlot: Codable {
    let hour: Int
    let minute: Int
    let utcDifference: Int
    let duration: Int

    init(hour: Int, minute: Int, utcDifference: Int, duration: Int) {
        self.hour = hour
        self.minute = minute
        self.utcDifference = utcDifference
        self.duration = duration
    }
}

private struct ScheduleItem: Codable {
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

struct ScheduleLessonRequest: Codable {
    let schedule: [Int: TimeSlot] // weekday (1-7) to TimeSlot mapping

    init(schedule: [Int: TimeSlot]) {
        self.schedule = schedule
    }

    private enum CodingKeys: String, CodingKey {
        case schedule
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Convert the dictionary to an array of ScheduleItem objects
        let scheduleArray = schedule.map { weekday, timeSlot in
            ScheduleItem(
                weekday: weekday,
                hour: timeSlot.hour,
                minute: timeSlot.minute,
                utcDifference: timeSlot.utcDifference,
                duration: timeSlot.duration
            )
        }

        try container.encode(scheduleArray, forKey: .schedule)
    }
}
