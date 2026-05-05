import Foundation
import Combine

@MainActor
final class TaskEditorViewModel: ObservableObject {
    enum Mode {
        case create
        case edit(Task)
    }

    @Published var title: String
    @Published var subtitle: String
    @Published private(set) var errorMessage: String?
    @Published private(set) var isSaving = false

    private let mode: Mode
    private let useCase: TaskEditorUseCase
    private let onSaved: () -> Void

    init(
        mode: Mode,
        useCase: TaskEditorUseCase,
        onSaved: @escaping () -> Void
    ) {
        self.mode = mode
        self.useCase = useCase
        self.onSaved = onSaved

        switch mode {
        case .create:
            title = ""
            subtitle = ""
        case .edit(let task):
            let parts = task.todo.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            title = parts.first.map(String.init) ?? ""
            subtitle = parts.count > 1 ? String(parts[1]) : ""
        }
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var dateText: String {
        Self.dateFormatter.string(from: Date())
    }

    func save(onSuccess: @escaping () -> Void) {
        guard canSave else { return }
        isSaving = true
        errorMessage = nil

        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSubtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .create:
            useCase.createTask(
                title: normalizedTitle,
                subtitle: normalizedSubtitle,
                completion: handleSaveResult(onSuccess: onSuccess)
            )
        case .edit(let task):
            useCase.updateTask(
                id: task.id,
                title: normalizedTitle,
                subtitle: normalizedSubtitle,
                completion: handleSaveResult(onSuccess: onSuccess)
            )
        }
    }

    private func handleSaveResult(onSuccess: @escaping () -> Void) -> (Result<Task, Error>) -> Void {
        { [weak self] result in
            guard let self else { return }
            self.isSaving = false

            switch result {
            case .success:
                self.onSaved()
                onSuccess()
            case .failure:
                self.errorMessage = "Не удалось сохранить задачу"
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
