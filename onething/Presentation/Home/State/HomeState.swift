import Foundation

struct HomeState: Equatable {
    var taskDraft: String = ""
    var isEditingTask: Bool = false
    var showResetConfirmation: Bool = false
    var showUndoToast: Bool = false
    var lastCompletedAt: Date? = nil
}
