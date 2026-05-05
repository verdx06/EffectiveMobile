//
//  EffectiveMobileTests.swift
//  EffectiveMobileTests
//
//  Created by Виталий Багаутдинов on 05.05.2026.
//

import XCTest
@testable import EffectiveMobile

final class MainUseCaseTests: XCTestCase {
    
    func test_execute_callsRepository() {
        // Given
        let repository = MockTaskRepository()
        let useCase = MainUseCaseImpl(repository: repository)
        
        // When
        useCase.execute { _ in }
        
        // Then
        XCTAssertTrue(repository.fetchTasksCalled)
    }
    
    func test_toggleCompleted_callsRepository() {
        // Given
        let repository = MockTaskRepository()
        let useCase = MainUseCaseImpl(repository: repository)
        
        // When
        useCase.toggleCompleted(id: 1) { _ in }
        
        // Then
        XCTAssertTrue(repository.toggleCompletedCalled)
    }
    
    func test_deleteTask_callsRepository() {
        // Given
        let repository = MockTaskRepository()
        let useCase = MainUseCaseImpl(repository: repository)
        
        // When
        useCase.deleteTask(id: 1) { _ in }
        
        // Then
        XCTAssertTrue(repository.deleteTaskCalled)
    }
}

// MARK: - Mock

class MockTaskRepository: TaskRepository {
    var fetchTasksCalled = false
    var toggleCompletedCalled = false
    var deleteTaskCalled = false
    
    func fetchTasks(completion: @escaping (Result<[Task], Error>) -> Void) {
        fetchTasksCalled = true
        completion(.success([]))
    }
    
    func createTask(title: String, subtitle: String, completion: @escaping (Result<Task, Error>) -> Void) {}
    
    func updateTask(id: Int, title: String, subtitle: String, completion: @escaping (Result<Task, Error>) -> Void) {}
    
    func toggleCompleted(id: Int, completion: @escaping (Result<Task, Error>) -> Void) {
        toggleCompletedCalled = true
        let task = Task(id: id, todo: "", completed: true, userId: 0)
        completion(.success(task))
    }
    
    func deleteTask(id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        deleteTaskCalled = true
        completion(.success(()))
    }
}

