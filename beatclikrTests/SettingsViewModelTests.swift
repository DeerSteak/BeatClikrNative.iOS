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
    private(set) var scheduledBodies: [String] = []
    private(set) var scheduledTime: Date?
    private(set) var rescheduledTime: Date?

    func checkAndRequestAuthorization() async -> NotificationAuthorizationResult {
        authorizationResult
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatus
    }

    func schedule(bodies: [String], at time: Date) {
        scheduledBodies = bodies; scheduledTime = time
    }

    func reschedule(at time: Date) {
        rescheduledTime = time
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
    }

    private func makeVM(
        notificationService: MockReminderNotificationService = MockReminderNotificationService()
    ) -> SettingsViewModel {
        SettingsViewModel(notificationService: notificationService)
    }

    // MARK: - Deferral persistence at init

    @Test func notificationsDeferredLocallyIsTrueWhenKeyPresent() {
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate
        )
        let vm = makeVM()
        #expect(vm.notificationsDeferredLocally == true)
    }

    // MARK: - declineRemindersFromOtherDevice

    @Test func declineRemindersFromOtherDeviceSetsFlag() {
        let vm = makeVM()
        vm.declineRemindersFromOtherDevice()
        #expect(vm.notificationsDeferredLocally == true)
    }

    @Test func declineRemindersFromOtherDeviceWritesToUserDefaults() {
        let vm = makeVM()
        vm.declineRemindersFromOtherDevice()
        #expect(UserDefaults.standard.object(forKey: PreferenceKeys.remindersDeferredDate) != nil)
    }

    // MARK: - Turning off sendReminders clears deferral

    @Test func turningOffSendRemindersClearsDeferralFlag() {
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate
        )
        let vm = makeVM()
        #expect(vm.notificationsDeferredLocally == true)
        vm.sendReminders = false
        #expect(vm.notificationsDeferredLocally == false)
    }

    @Test func turningOffSendRemindersClearsDeferralFromUserDefaults() {
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate
        )
        let vm = makeVM()
        vm.sendReminders = false
        #expect(UserDefaults.standard.object(forKey: PreferenceKeys.remindersDeferredDate) == nil)
    }

    @Test func turningOffSendRemindersCancelsNotifications() {
        let mock = MockReminderNotificationService()
        let vm = SettingsViewModel(notificationService: mock)
        vm.sendReminders = false
        #expect(mock.cancelCalled == true)
    }

    // MARK: - External trigger (checkPermissionsFromExternalTrigger via init)

    @Test func externalTriggerAuthorizedSchedulesAndClearsDeferral() async {
        let mock = MockReminderNotificationService()
        mock.authorizationStatus = .authorized
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate
        )
        UserDefaultsService.instance.sendReminders = true
        let vm = SettingsViewModel(notificationService: mock)
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.notificationsBlockedLocally == false)
        #expect(vm.notificationsDeferredLocally == false)
        #expect(mock.rescheduledTime != nil)
    }

    @Test func externalTriggerDeniedSetsBlockedFlag() async {
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

    @Test func externalTriggerNotDeterminedShowsPromptWhenNotDeferred() async {
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

    @Test func externalTriggerNotDeterminedDoesNotShowPromptWhenDeferred() async {
        let mock = MockReminderNotificationService()
        mock.authorizationStatus = .notDetermined
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate
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

    @Test func userTogglesOnGrantedClearsDeferralAndSchedules() async {
        let mock = MockReminderNotificationService()
        mock.authorizationResult = .granted
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate
        )
        let vm = SettingsViewModel(notificationService: mock)
        vm.sendReminders = true
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.notificationsDeferredLocally == false)
        #expect(vm.notificationsBlockedLocally == false)
        #expect(mock.rescheduledTime != nil)
    }

    @Test func userTogglesOnDeniedFlipsToggleAndShowsAlert() async {
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

    @Test func userTogglesOnNotGrantedFlipsToggleWithoutAlert() async {
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

    @Test func allowRemindersGrantedClearsDeferralAndSchedules() async {
        let mock = MockReminderNotificationService()
        mock.authorizationResult = .granted
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate
        )
        let vm = SettingsViewModel(notificationService: mock)
        vm.allowRemindersFromOtherDevice()
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        #expect(vm.notificationsDeferredLocally == false)
        #expect(vm.notificationsBlockedLocally == false)
        #expect(mock.rescheduledTime != nil)
    }

    @Test func allowRemindersDeniedSetsBlockedAndClearsDeferral() async {
        let mock = MockReminderNotificationService()
        mock.authorizationResult = .denied
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate
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

    @Test func refreshStatusClearsBlockedFlagWhenNowAuthorized() async {
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
}
