//
//  ReminderNotificationService.swift
//  beatclikr
//
//  Created by Ben Funk on 5/2/26.
//

import Foundation
import UserNotifications

enum NotificationAuthorizationResult {
    case granted, denied, notGranted
}

enum ReminderTimeZonePolicy: Equatable, Sendable {
    /// Keep the selected hour and minute in the device's current time zone.
    /// BeatClikr rebuilds the plan when it becomes active, so travel adopts the
    /// new local time zone instead of retaining the original absolute instant.
    case currentLocalTime
}

struct ReminderOccurrence: Equatable, Sendable {
    let identifier: String
    let fireDate: Date
    let title: String
    let body: String
    let timeZone: TimeZone
}

struct ReminderPlan: Equatable, Sendable {
    static let occurrenceCount = 7
    static let identifierPrefix = "practiceReminder_"

    let occurrences: [ReminderOccurrence]
    let timeZonePolicy: ReminderTimeZonePolicy

    var identifiers: [String] {
        occurrences.map(\.identifier)
    }

    static func build(
        reminderTime: Date,
        now: Date = .now,
        calendar sourceCalendar: Calendar = .current,
        bodyForDate: (Date) -> String,
    ) -> ReminderPlan {
        let calendar = sourceCalendar
        let timeZone = calendar.timeZone
        let selectedTime = calendar.dateComponents([.hour, .minute], from: reminderTime)
        let startOfToday = calendar.startOfDay(for: now)
        var occurrences: [ReminderOccurrence] = []
        var dayOffset = 0

        while occurrences.count < occurrenceCount {
            defer { dayOffset += 1 }
            guard
                let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday),
                let hour = selectedTime.hour,
                let minute = selectedTime.minute,
                let fireDate = calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: day,
                    matchingPolicy: .nextTimePreservingSmallerComponents,
                    repeatedTimePolicy: .first,
                    direction: .forward,
                ),
                calendar.isDate(fireDate, inSameDayAs: day),
                fireDate > now
            else {
                continue
            }

            let index = occurrences.count
            occurrences.append(
                ReminderOccurrence(
                    identifier: "\(identifierPrefix)\(index)",
                    fireDate: fireDate,
                    title: String(localized: "PracticeReminderNotificationTitle"),
                    body: bodyForDate(day),
                    timeZone: timeZone,
                ),
            )
        }

        return ReminderPlan(
            occurrences: occurrences,
            timeZonePolicy: .currentLocalTime,
        )
    }
}

enum ReminderSchedulingResult: Equatable {
    case scheduled(count: Int)
    case failed(message: String)
}

@MainActor
protocol ReminderNotificationServicing: AnyObject {
    func checkAndRequestAuthorization() async -> NotificationAuthorizationResult
    func currentAuthorizationStatus() async -> UNAuthorizationStatus
    func replaceSchedule(with plan: ReminderPlan) async -> ReminderSchedulingResult
    func cancel()
}

@MainActor
final class ReminderNotificationService: ReminderNotificationServicing {
    private static let legacyIdentifier = "practiceReminder"

    func checkAndRequestAuthorization() async -> NotificationAuthorizationResult {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .denied { return .denied }
        let granted = await (try? center.requestAuthorization(options: [.alert, .sound])) ?? false
        return granted ? .granted : .notGranted
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func replaceSchedule(with plan: ReminderPlan) async -> ReminderSchedulingResult {
        guard plan.occurrences.count == ReminderPlan.occurrenceCount,
              plan.occurrences.allSatisfy({ $0.fireDate > .now })
        else {
            return .failed(message: "The reminder plan did not contain seven future occurrences.")
        }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: managedIdentifiers)

        do {
            for occurrence in plan.occurrences {
                try Task.checkCancellation()
                let content = UNMutableNotificationContent()
                content.title = occurrence.title
                content.body = occurrence.body
                content.sound = .default

                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = occurrence.timeZone
                var components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: occurrence.fireDate,
                )
                components.timeZone = occurrence.timeZone
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                try await center.add(
                    UNNotificationRequest(
                        identifier: occurrence.identifier,
                        content: content,
                        trigger: trigger,
                    ),
                )
            }
        } catch {
            center.removePendingNotificationRequests(withIdentifiers: managedIdentifiers)
            return .failed(message: error.localizedDescription)
        }

        let pending = await center.pendingNotificationRequests()
        let pendingByIdentifier = Dictionary(uniqueKeysWithValues: pending.map { ($0.identifier, $0) })
        let retainedCompletePlan = plan.occurrences.allSatisfy { occurrence in
            guard
                let request = pendingByIdentifier[occurrence.identifier],
                request.content.title == occurrence.title,
                request.content.body == occurrence.body,
                let trigger = request.trigger as? UNCalendarNotificationTrigger,
                let nextFireDate = trigger.nextTriggerDate()
            else {
                return false
            }
            return abs(nextFireDate.timeIntervalSince(occurrence.fireDate)) < 1
        }
        guard retainedCompletePlan else {
            center.removePendingNotificationRequests(withIdentifiers: managedIdentifiers)
            return .failed(message: "The notification center did not retain the complete reminder plan.")
        }
        return .scheduled(count: plan.occurrences.count)
    }

    func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: managedIdentifiers)
    }

    private var managedIdentifiers: [String] {
        (0 ..< ReminderPlan.occurrenceCount)
            .map { "\(ReminderPlan.identifierPrefix)\($0)" } + [Self.legacyIdentifier]
    }
}
