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

@MainActor
protocol ReminderNotificationServicing: AnyObject {
    func checkAndRequestAuthorization() async -> NotificationAuthorizationResult
    func currentAuthorizationStatus() async -> UNAuthorizationStatus
    func schedule(bodies: [String], at time: Date)
    func reschedule(at time: Date)
    func cancel()
}

@MainActor
class ReminderNotificationService: ReminderNotificationServicing {

    private var cachedBodies: [String] = [String(localized: "PracticeReminderNotificationBody")]

    func checkAndRequestAuthorization() async -> NotificationAuthorizationResult {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .denied { return .denied }
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        return granted ? .granted : .notGranted
    }
    
    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
    
    func schedule(bodies: [String], at time: Date) {
        cachedBodies = bodies
        performSchedule(bodies: bodies, at: time)
    }
    
    func reschedule(at time: Date) {
        performSchedule(bodies: cachedBodies, at: time)
    }
    
    func cancel() {
        let allIds = (0..<7).map { "practiceReminder_\($0)" } + ["practiceReminder"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allIds)
    }
    
    private func performSchedule(bodies: [String], at time: Date) {
        let center = UNUserNotificationCenter.current()
        let allIds = (0..<7).map { "practiceReminder_\($0)" } + ["practiceReminder"]
        center.removePendingNotificationRequests(withIdentifiers: allIds)
        
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let hourMinute = cal.dateComponents([.hour, .minute], from: time)
        
        for (offset, body) in bodies.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "PracticeReminderNotificationTitle")
            content.body = body
            content.sound = .default
            
            let fireDay = cal.date(byAdding: .day, value: offset, to: today)!
            var components = cal.dateComponents([.year, .month, .day], from: fireDay)
            components.hour = hourMinute.hour
            components.minute = hourMinute.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "practiceReminder_\(offset)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
}
