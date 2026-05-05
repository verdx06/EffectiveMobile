import Foundation
import Combine

@MainActor
final class MainViewModel: ObservableObject {
    @Published private(set) var tasks: [Task] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var searchText = ""

    private let useCase: MainUseCase

    init(useCase: MainUseCase) {
        self.useCase = useCase
    }

    func loadTasks() {
        isLoading = true
        errorMessage = nil

        useCase.execute { [weak self] result in
            guard let self else { return }
            self.isLoading = false

            switch result {
            case .success(let tasks):
                self.tasks = tasks
            case .failure:
                self.errorMessage = "Не удалось загрузить задачи"
            }
        }
    }

    var filteredTasks: [Task] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return tasks }
        return tasks.filter { $0.todo.localizedCaseInsensitiveContains(trimmed) }
    }

    func toggleCompleted(id: Int) {
        useCase.toggleCompleted(id: id) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let updatedTask):
                guard let index = self.tasks.firstIndex(where: { $0.id == id }) else { return }
                self.tasks[index] = updatedTask
            case .failure:
                self.errorMessage = "Не удалось обновить статус"
            }
        }
    }

    func deleteTask(id: Int) {
        useCase.deleteTask(id: id) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                self.tasks.removeAll { $0.id == id }
            case .failure:
                self.errorMessage = "Не удалось удалить задачу"
            }
        }
    }

}
