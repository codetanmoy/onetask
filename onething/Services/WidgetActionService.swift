import Foundation
import SwiftData
import Combine

/// Service that handles actions triggered from the widget/Live Activity
/// Uses App Groups and UserDefaults to communicate between widget and app
@MainActor
final class WidgetActionService: ObservableObject {
    static let shared = WidgetActionService()
    
    // Published so views can react to pending actions
    @Published private(set) var pendingAction: WidgetAction?
    
    private let actionKey = "pendingWidgetAction"
    private let userDefaults: UserDefaults?
    
    private init() {
        // Use App Group for widget-app communication
        self.userDefaults = UserDefaults(suiteName: "group.com.qps.onething")
        
        // Check for any pending actions on launch
        checkPendingAction()
    }
    
    /// Called by the app to check if there's a pending action from the widget
    func checkPendingAction() {
        guard let actionRaw = userDefaults?.string(forKey: actionKey),
              let action = WidgetAction(rawValue: actionRaw) else {
            pendingAction = nil
            return
        }
        pendingAction = action
    }
    
    /// Process and clear the pending action
    func processPendingAction(context: ModelContext, options: HomeOptions, viewModel: HomeViewModel) {
        guard let action = pendingAction else { return }
        
        switch action {
        case .pause:
            // Trigger pause action (only if running)
            if viewModel.entry?.isRunning == true {
                viewModel.handle(.startStopTapped, context: context, options: options)
            }
        case .complete:
            // Trigger complete action
            viewModel.handle(.markDoneTapped, context: context, options: options)
        case .resume:
            // Trigger resume (only if paused)
            if viewModel.entry?.isRunning == false {
                viewModel.handle(.startStopTapped, context: context, options: options)
            }
        }
        
        // Sync the Live Activity with the updated entry state
        if let entry = viewModel.entry {
            Task {
                await LiveActivityService.sync(entry: entry)
            }
        }
        
        // Clear the pending action
        clearPendingAction()
    }
    
    /// Set a pending action from the widget
    func setPendingAction(_ action: WidgetAction) {
        userDefaults?.set(action.rawValue, forKey: actionKey)
        userDefaults?.synchronize()
        pendingAction = action
    }
    
    /// Clear the pending action
    func clearPendingAction() {
        userDefaults?.removeObject(forKey: actionKey)
        userDefaults?.synchronize()
        pendingAction = nil
    }
}

// MARK: - Widget Action Enum
enum WidgetAction: String {
    case pause
    case complete
    case resume
}
