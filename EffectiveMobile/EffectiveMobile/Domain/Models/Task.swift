struct Task: Codable, Identifiable, Hashable {
    let id: Int
    var todo: String
    var completed: Bool
    let userId: Int
}

struct TaskList: Codable {
    var todos: [Task]
    var total: Int
    var skip: Int
    var limit: Int
}


