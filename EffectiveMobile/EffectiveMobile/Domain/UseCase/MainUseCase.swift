import Foundation

protocol MainUseCase {
    func execute(completion: @escaping (Result<[Task], Error>) -> Void)
    func toggleCompleted(id: Int, completion: @escaping (Result<Task, Error>) -> Void)
    func deleteTask(id: Int, completion: @escaping (Result<Void, Error>) -> Void)
}

final class MainUseCaseImpl: MainUseCase {
    private let repository: TaskRepository

    init(repository: TaskRepository) {
        self.repository = repository
    }

    func execute(completion: @escaping (Result<[Task], Error>) -> Void) {
        repository.fetchTasks(completion: completion)
    }

    func toggleCompleted(id: Int, completion: @escaping (Result<Task, Error>) -> Void) {
        repository.toggleCompleted(id: id, completion: completion)
    }

    func deleteTask(id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        repository.deleteTask(id: id, completion: completion)
    }
}
