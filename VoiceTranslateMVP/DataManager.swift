import Foundation

class DataManager {
    static let shared = DataManager()
    
    private let key = "customWords"
    
    func fetchCustomWords() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    func saveWords(_ words: [String]) {
        UserDefaults.standard.set(words, forKey: key)
    }
}

