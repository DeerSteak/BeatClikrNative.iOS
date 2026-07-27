//
//  SettingsViewModelTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 5/4/26.
//

@testable import BeatClikr
import Foundation
import Testing
import UserNotifications

@MainActor
final class MockReminderNotificationService: ReminderNotificationServicing {
    var authorizationResult: NotificationAuthorizationResult = .granted
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var cancelCalled = false
    private(set) var scheduledPlan: ReminderPlan?
    var schedulingResult: ReminderSchedulingResult = .scheduled(count: 7)

    func checkAndRequestAuthorization() async -> NotificationAuthorizationResult {
        authorizationResult
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatus
    }

    func replaceSchedule(with plan: ReminderPlan) async -> ReminderSchedulingResult {
        scheduledPlan = plan
        return schedulingResult
    }

    func cancel() {
        cancelCalled = true
    }
}

@MainActor
struct SettingsViewModelTests {
    init() {
        // Reset shared state before each test; done before UserDefaultsService.instance is accessed
        UserDefaults.standard.removeObject(forKey: PreferenceKeys.remindersDeferredDate)
        UserDefaultsService.instance.sendReminders = false
        UserDefaultsService.instance.alwaysUseDarkTheme = false
    }

    private func makeVM(
        notificationService: MockReminderNotificationService = MockReminderNotificationService(),
    ) -> SettingsViewModel {
        SettingsViewModel(notificationService: notificationService)
    }

    // MARK: - Appearance

    @Test func `always use dark theme persists when toggled`() {
        let vm = makeVM()
        vm.alwaysUseDarkTheme = true
        #expect(UserDefaultsService.instance.alwaysUseDarkTheme == true)
    }

    // MARK: - Deferral persistence at init

    @Test func `notifications deferred locally is true when key present`() {
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate,
        )
        let vm = makeVM()
        #expect(vm.notificationsDeferredLocally == true)
    }

    // MARK: - declineRemindersFromOtherDevice

    @Test func `decline reminders from other device sets flag`() {
        let vm = makeVM()
        vm.declineRemindersFromOtherDevice()
        #expect(vm.notificationsDeferredLocally == true)
    }

    @Test func `decline reminders from other device writes to user defaults`() {
        let vm = makeVM()
        vm.declineRemindersFromOtherDevice()
        #expect(UserDefaults.standard.object(forKey: PreferenceKeys.remindersDeferredDate) != nil)
    }

    // MARK: - Turning off sendReminders clears deferral

    @Test func `turning off send reminders clears deferral flag`() {
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate,
        )
        let vm = makeVM()
        #expect(vm.notificationsDeferredLocally == true)
        vm.sendReminders = false
        #expect(vm.notificationsDeferredLocally == false)
    }

    @Test func `turning off send reminders clears deferral from user defaults`() {
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate,
        )
        let vm = makeVM()
        vm.sendReminders = false
        #expect(UserDefaults.standard.object(forKey: PreferenceKeys.remindersDeferredDate) == nil)
    }

    @Test func `turning off send reminders cancels notifications`() {
        let mock = MockReminderNotificationService()
        let vm = SettingsViewModel(notificationService: mock)
        vm.sendReminders = false
        #expect(mock.cancelCalled == true)
    }

    // MARK: - External trigger (checkPermissionsFromExternalTrigger via init)

    @Test func `external trigger authorized schedules and clears deferral`() async {
        let mock = MockReminderNotificationService()
        mock.authorizationStatus = .authorized
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate,
        )
        UserDefaultsService.instance.sendReminders = true
        let vm = SettingsViewModel(notificationService: mock)
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.notificationsBlockedLocally == false)
        #expect(vm.notificationsDeferredLocally == false)
        #expect(mock.scheduledPlan != nil)
    }

    @Test func `external trigger denied sets blocked flag`() async {
        let mock = MockReminderNotificationService()
        mock.authorizationStatus = .denied
        UserDefaultsService.instance.sendReminders = true
        let vm = SettingsViewModel(notificationService: mock)
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.notificationsBlockedLocally == true)
        #expect(vm.showCrossDeviceReminderPrompt == false)
    }

    @Test func `external trigger not determined shows prompt when not deferred`() async {
        let mock = MockReminderNotificationService()
        mock.authorizationStatus = .notDetermined
        UserDefaultsService.instance.sendReminders = true
        let vm = SettingsViewModel(notificationService: mock)
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.showCrossDeviceReminderPrompt == true)
        #expect(vm.notificationsBlockedLocally == false)
    }

    @Test func `external trigger not determined does not show prompt when deferred`() async {
        let mock = MockReminderNotificationService()
        mock.authorizationStatus = .notDetermined
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate,
        )
        UserDefaultsService.instance.sendReminders = true
        let vm = SettingsViewModel(notificationService: mock)
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.showCrossDeviceReminderPrompt == false)
        #expect(vm.notificationsDeferredLocally == true)
    }

    // MARK: - User-initiated toggle (requestPermissionAndSchedule)

    @Test func `user toggles on granted clears deferral and schedules`() async {
        let mock = MockReminderNotificationService()
        mock.authorizationResult = .granted
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate,
        )
        let vm = SettingsViewModel(notificationService: mock)
        vm.sendReminders = true
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.notificationsDeferredLocally == false)
        #expect(vm.notificationsBlockedLocally == false)
        #expect(mock.scheduledPlan != nil)
    }

    @Test func `user toggles on denied flips toggle and shows alert`() async {
        let mock = MockReminderNotificationService()
        mock.authorizationResult = .denied
        let vm = SettingsViewModel(notificationService: mock)
        vm.sendReminders = true
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.sendReminders == false)
        #expect(vm.showPermissionDeniedAlert == true)
    }

    @Test func `user toggles on not granted flips toggle without alert`() async {
        let mock = MockReminderNotificationService()
        mock.authorizationResult = .notGranted
        let vm = SettingsViewModel(notificationService: mock)
        vm.sendReminders = true
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.sendReminders == false)
        #expect(vm.showPermissionDeniedAlert == false)
    }

    // MARK: - allowRemindersFromOtherDevice

    @Test func `allow reminders granted clears deferral and schedules`() async {
        let mock = MockReminderNotificationService()
        mock.authorizationResult = .granted
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate,
        )
        let vm = SettingsViewModel(notificationService: mock)
        vm.allowRemindersFromOtherDevice()
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.notificationsDeferredLocally == false)
        #expect(vm.notificationsBlockedLocally == false)
        #expect(mock.scheduledPlan != nil)
    }

    @Test func `allow reminders denied sets blocked and clears deferral`() async {
        let mock = MockReminderNotificationService()
        mock.authorizationResult = .denied
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate,
        )
        let vm = SettingsViewModel(notificationService: mock)
        vm.allowRemindersFromOtherDevice()
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.notificationsBlockedLocally == true)
        #expect(vm.notificationsDeferredLocally == false)
    }

    // MARK: - refreshNotificationStatus

    @Test func `refresh status clears blocked flag when now authorized`() async {
        let mock = MockReminderNotificationService()
        mock.authorizationStatus = .denied
        UserDefaultsService.instance.sendReminders = true
        let vm = SettingsViewModel(notificationService: mock)
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.notificationsBlockedLocally == true)

        mock.authorizationStatus = .authorized
        vm.refreshNotificationStatus()
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.notificationsBlockedLocally == false)
    }

    @Test func `refresh status marks reminders blocked when permission was revoked`() async {
        let mock = MockReminderNotificationService()
        mock.authorizationStatus = .authorized
        UserDefaultsService.instance.sendReminders = true
        let vm = SettingsViewModel(notificationService: mock)
        for _ in 0 ..< 3 {
            await Task.yield()
        }

        mock.authorizationStatus = .denied
        vm.refreshNotificationStatus()
        for _ in 0 ..< 3 {
            await Task.yield()
        }

        #expect(vm.notificationsBlockedLocally == true)
        #expect(mock.cancelCalled == true)
    }

    @Test func `scheduling failure is visible in local state`() async {
        let mock = MockReminderNotificationService()
        mock.authorizationResult = .granted
        mock.schedulingResult = .failed(message: "Notifications unavailable")
        let vm = SettingsViewModel(notificationService: mock)

        vm.sendReminders = true
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.reminderSchedulingError == "Notifications unavailable")
    }
}

struct ReminderPlanTests {
    private let utc = TimeZone(secondsFromGMT: 0)!

    @Test func `future reminder time includes today and six following days`() {
        let calendar = calendar(timeZone: utc)
        let now = date(2026, 7, 27, 9, 0, calendar: calendar)
        let reminderTime = date(2001, 1, 1, 18, 30, calendar: calendar)

        let plan = ReminderPlan.build(
            reminderTime: reminderTime,
            now: now,
            calendar: calendar,
        ) { $0.formatted(.iso8601.year().month().day()) }

        #expect(plan.occurrences.count == 7)
        #expect(plan.occurrences.first?.fireDate == date(2026, 7, 27, 18, 30, calendar: calendar))
        #expect(plan.occurrences.last?.fireDate == date(2026, 8, 2, 18, 30, calendar: calendar))
        #expect(Set(plan.identifiers).count == 7)
    }

    @Test func `past reminder time skips today and still creates seven occurrences`() {
        let calendar = calendar(timeZone: utc)
        let now = date(2026, 7, 27, 19, 0, calendar: calendar)
        let reminderTime = date(2001, 1, 1, 18, 30, calendar: calendar)

        let plan = ReminderPlan.build(
            reminderTime: reminderTime,
            now: now,
            calendar: calendar,
        ) { _ in "Practice" }

        #expect(plan.occurrences.count == 7)
        #expect(plan.occurrences.first?.fireDate == date(2026, 7, 28, 18, 30, calendar: calendar))
        #expect(plan.occurrences.last?.fireDate == date(2026, 8, 3, 18, 30, calendar: calendar))
    }

    @Test func `spring DST gap advances to the next valid local time`() throws {
        let zone = try #require(TimeZone(identifier: "America/Chicago"))
        let calendar = calendar(timeZone: zone)
        let now = date(2026, 3, 7, 12, 0, calendar: calendar)
        let reminderTime = date(2001, 1, 1, 2, 30, calendar: calendar)

        let plan = ReminderPlan.build(
            reminderTime: reminderTime,
            now: now,
            calendar: calendar,
        ) { _ in "Practice" }

        let march8 = plan.occurrences[0].fireDate
        let components = calendar.dateComponents([.day, .hour, .minute], from: march8)
        #expect(components.day == 8)
        #expect(components.hour == 3)
        #expect(components.minute == 0)
    }

    @Test func `fall DST overlap schedules exactly one deterministic occurrence`() throws {
        let zone = try #require(TimeZone(identifier: "America/Chicago"))
        let calendar = calendar(timeZone: zone)
        let now = date(2026, 10, 31, 12, 0, calendar: calendar)
        let reminderTime = date(2001, 1, 1, 1, 30, calendar: calendar)

        let plan = ReminderPlan.build(
            reminderTime: reminderTime,
            now: now,
            calendar: calendar,
        ) { _ in "Practice" }

        let november1 = plan.occurrences[0].fireDate
        let components = calendar.dateComponents([.day, .hour, .minute], from: november1)
        #expect(components.day == 1)
        #expect(components.hour == 1)
        #expect(components.minute == 30)
        #expect(plan.occurrences.filter { calendar.isDate($0.fireDate, inSameDayAs: november1) }.count == 1)
    }

    @Test func `travel rebuild uses the new current local time zone`() throws {
        let chicago = try calendar(timeZone: #require(TimeZone(identifier: "America/Chicago")))
        let losAngeles = try calendar(timeZone: #require(TimeZone(identifier: "America/Los_Angeles")))
        let chicagoReminderTime = date(2001, 1, 1, 18, 30, calendar: chicago)
        let losAngelesReminderTime = date(2001, 1, 1, 18, 30, calendar: losAngeles)

        let chicagoPlan = ReminderPlan.build(
            reminderTime: chicagoReminderTime,
            now: date(2026, 7, 27, 9, 0, calendar: chicago),
            calendar: chicago,
        ) { _ in "Practice" }
        let losAngelesPlan = ReminderPlan.build(
            reminderTime: losAngelesReminderTime,
            now: date(2026, 7, 27, 9, 0, calendar: losAngeles),
            calendar: losAngeles,
        ) { _ in "Practice" }

        #expect(chicago.dateComponents([.hour, .minute], from: chicagoPlan.occurrences[0].fireDate).hour == 18)
        #expect(losAngeles.dateComponents([.hour, .minute], from: losAngelesPlan.occurrences[0].fireDate).hour == 18)
        #expect(chicagoPlan.occurrences[0].timeZone != losAngelesPlan.occurrences[0].timeZone)
    }

    private func calendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int,
        calendar: Calendar,
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
            ),
        )!
    }
}
