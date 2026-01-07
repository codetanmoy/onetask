import SwiftUI
import SwiftData

struct HomeTaskBlock: View {
    @Environment(\.modelContext) private var modelContext

    let entry: DayEntry?
    let isCompleted: Bool
    let options: HomeOptions
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            OneThingSectionHeader(title: "One thing")

            if isCompleted {
                Text(entry?.taskText.isEmpty == false ? entry!.taskText : "—")
                    .font(.title2)
                    .fontWeight(.semibold)
            } else {
                TextField("What's the one thing?", text: taskDraftBinding)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .textInputAutocapitalization(.sentences)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .disableAutocorrection(false)
                    .submitLabel(.done)
                    .onChange(of: viewModel.state.taskDraft) { _, newValue in
                        viewModel.handle(.setTask(newValue), context: modelContext, options: options)
                    }
                    .onSubmit {
                        viewModel.handle(.setTask(viewModel.state.taskDraft), context: modelContext, options: options)
                    }
                
                // Show suggestions when task is empty
                if viewModel.state.taskDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    TaskSuggestionChips(suggestions: viewModel.state.suggestions) { suggestion in
                        viewModel.state.taskDraft = suggestion
                        viewModel.handle(.setTask(suggestion), context: modelContext, options: options)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var taskDraftBinding: Binding<String> {
        Binding(
            get: { viewModel.state.taskDraft },
            set: { viewModel.state.taskDraft = String($0.prefix(Constants.maxTaskLength)) }
        )
    }
}

