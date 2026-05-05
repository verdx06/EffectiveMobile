import SwiftUI

@main
struct EffectiveMobileApp: App {
    private let repository = TaskRepositoryImpl(networkService: NetworkServiceImpl())

    var body: some Scene {
        WindowGroup {
            MainView(
                viewModel: MainViewModel(
                    useCase: MainUseCaseImpl(
                        repository: repository
                    )
                ),
                taskEditorUseCase: TaskEditorUseCaseImpl(repository: repository)
            )
        }
    }
}
