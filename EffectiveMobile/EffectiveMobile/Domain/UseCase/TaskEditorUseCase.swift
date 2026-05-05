import Foundation

protocol TaskEditorUseCase {
    func createTask(
        title: String,
        subtitle: String,
        completion: @escaping (Result<Task, Error>) -> Void
    )

    func updateTask(
        id: Int,
        title: String,
        subtitle: String,
        completion: @escaping (Result<Task, Error>) -> Void
    )
}

final class TaskEditorUseCaseImpl: TaskEditorUseCase {
    private let repository: TaskRepository

    init(repository: TaskRepository) {
        self.repository = repository
    }

    func createTask(
        title: String,
        subtitle: String,
        completion: @escaping (Result<Task, Error>) -> Void
    ) {
        repository.createTask(title: title, subtitle: subtitle, completion: completion)
    }

    func updateTask(
        id: Int,
        title: String,
        subtitle: String,
        completion: @escaping (Result<Task, Error>) -> Void
    ) {
        repository.updateTask(id: id, title: title, subtitle: subtitle, completion: completion)
    }
}
