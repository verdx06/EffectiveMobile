import Foundation
import CoreData

protocol TaskRepository {
    func fetchTasks(completion: @escaping (Result<[Task], Error>) -> Void)
    func createTask(title: String, subtitle: String, completion: @escaping (Result<Task, Error>) -> Void)
    func updateTask(id: Int, title: String, subtitle: String, completion: @escaping (Result<Task, Error>) -> Void)
    func toggleCompleted(id: Int, completion: @escaping (Result<Task, Error>) -> Void)
    func deleteTask(id: Int, completion: @escaping (Result<Void, Error>) -> Void)
}

final class TaskRepositoryImpl {
    private let networkService: NetworkService
    private let context: NSManagedObjectContext
    
    init(
        networkService: NetworkService,
        context: NSManagedObjectContext = PersistenceController.shared.container.viewContext
    ) {
        self.networkService = networkService
        self.context = context
    }
}

extension TaskRepositoryImpl: TaskRepository {
    func fetchTasks(completion: @escaping (Result<[Task], Error>) -> Void) {
        networkService.request(endpoint: .todos) { (result: Result<TaskList, Error>) in
            switch result {
            case .success(let response):
                do {
                    try self.upsertRemoteTasks(response.todos)
                    let localTasks = try self.fetchLocalTasks()
                    completion(.success(localTasks))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                do {
                    let localTasks = try self.fetchLocalTasks()
                    if localTasks.isEmpty {
                        completion(.failure(error))
                    } else {
                        completion(.success(localTasks))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func createTask(title: String, subtitle: String, completion: @escaping (Result<Task, Error>) -> Void) {
        do {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Constants.entityName)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Constants.idKey, ascending: false)]
            fetchRequest.fetchLimit = 1

            let maxId = try context.fetch(fetchRequest).first?.value(forKey: Constants.idKey) as? Int64 ?? 0
            let nextId = maxId + 1

            let item = try createTaskObject(id: nextId)
            item.apply(title: title, subtitle: subtitle, completed: false, userId: 0)

            try context.save()

            completion(.success(item.toTask()))
        } catch {
            completion(.failure(error))
        }
    }

    func updateTask(id: Int, title: String, subtitle: String, completion: @escaping (Result<Task, Error>) -> Void) {
        do {
            guard let item = try findTaskObject(id: id) else {
                completion(.failure(NSError(domain: "CoreData", code: 404)))
                return
            }

            item.setValue(title, forKey: Constants.titleKey)
            item.setValue(subtitle, forKey: Constants.subtitleKey)

            try context.save()

            completion(.success(item.toTask()))
        } catch {
            completion(.failure(error))
        }
    }

    func toggleCompleted(id: Int, completion: @escaping (Result<Task, Error>) -> Void) {
        do {
            guard let item = try findTaskObject(id: id) else {
                completion(.failure(NSError(domain: "CoreData", code: 404)))
                return
            }

            let oldValue = item.value(forKey: Constants.completedKey) as? Bool ?? false
            let newValue = !oldValue
            item.setValue(newValue, forKey: Constants.completedKey)
            try context.save()

            completion(.success(item.toTask()))
        } catch {
            completion(.failure(error))
        }
    }

    func deleteTask(id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            guard let item = try findTaskObject(id: id) else {
                completion(.success(()))
                return
            }

            context.delete(item)
            try context.save()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}

private extension TaskRepositoryImpl {
    func upsertRemoteTasks(_ tasks: [Task]) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: Constants.entityName)
        let existing = try context.fetch(request)

        var existingById = Dictionary(uniqueKeysWithValues: existing.map {
            (($0.value(forKey: Constants.idKey) as? Int64 ?? 0), $0)
        })

        for task in tasks {
            let taskId = Int64(task.id)
            let item: NSManagedObject
            if let existingItem = existingById[taskId] {
                item = existingItem
            } else {
                item = try createTaskObject(id: taskId)
                existingById[taskId] = item
            }

            let (title, subtitle) = Self.split(todo: task.todo)
            item.apply(title: title, subtitle: subtitle, completed: task.completed, userId: Int64(task.userId))
            if (item.value(forKey: Constants.dateKey) as? String)?.isEmpty ?? true {
                item.setValue(Self.dateFormatter.string(from: Date()), forKey: Constants.dateKey)
            }
        }

        if context.hasChanges {
            try context.save()
        }
    }

    func fetchLocalTasks() throws -> [Task] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Constants.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: Constants.idKey, ascending: false)]
        return try context.fetch(request).map { $0.toTask() }
    }

    func findTaskObject(id: Int) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: Constants.entityName)
        request.predicate = NSPredicate(format: "%K == %d", Constants.idKey, id)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func createTaskObject(id: Int64) throws -> NSManagedObject {
        guard let entity = NSEntityDescription.entity(forEntityName: Constants.entityName, in: context) else {
            throw NSError(domain: "CoreData", code: 1)
        }
        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(id, forKey: Constants.idKey)
        object.setValue(Self.dateFormatter.string(from: Date()), forKey: Constants.dateKey)
        return object
    }

    static func split(todo: String) -> (title: String, subtitle: String) {
        let parts = todo.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        let title = parts.first.map(String.init) ?? ""
        let subtitle = parts.count > 1 ? String(parts[1]) : ""
        return (title, subtitle)
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

private enum Constants {
    static let entityName = "TasksEntity"
    static let idKey = "id"
    static let titleKey = "title"
    static let subtitleKey = "subtitle"
    static let completedKey = "completed"
    static let dateKey = "date"
    static let userIdKey = "userId"
}

private extension NSManagedObject {
    func apply(title: String, subtitle: String, completed: Bool, userId: Int64) {
        setValue(title, forKey: Constants.titleKey)
        setValue(subtitle, forKey: Constants.subtitleKey)
        setValue(completed, forKey: Constants.completedKey)
        setValue(userId, forKey: Constants.userIdKey)
    }

    func toTask() -> Task {
        let id = Int(value(forKey: Constants.idKey) as? Int64 ?? 0)
        let title = value(forKey: Constants.titleKey) as? String ?? ""
        let subtitle = value(forKey: Constants.subtitleKey) as? String ?? ""
        let completed = value(forKey: Constants.completedKey) as? Bool ?? false
        let userId = Int(value(forKey: Constants.userIdKey) as? Int64 ?? 0)
        let todo = subtitle.isEmpty ? title : "\(title)\n\(subtitle)"
        return Task(id: id, todo: todo, completed: completed, userId: userId)
    }
}
