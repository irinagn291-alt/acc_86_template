import SwiftUI
import SwiftData
import Combine

@MainActor
final class PenduloraServices: ObservableObject {
    let preferences: LuxPreferences
    let setRepository: SwingSetRepository
    let recordRepository: SwingRecordRepository

    private var cancellables = Set<AnyCancellable>()

    init(context: ModelContext) {
        preferences = LuxPreferences()
        setRepository = SwingSetRepository(context: context)
        recordRepository = SwingRecordRepository(context: context)
        preferences.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
}
