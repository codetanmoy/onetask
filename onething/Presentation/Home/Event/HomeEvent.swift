import Foundation

enum HomeEvent {
    case onAppear
    case setTask(String)
    case startStopTapped
    case resetConfirmed
    case markDoneTapped
    case undoDone
    case startAnotherTask
}
