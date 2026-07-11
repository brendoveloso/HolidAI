import Foundation
import SwiftData

@Model
final class HolidayCache {
    @Attribute(.unique) var id: String
    var date: Date
    var name: String
    var type: String
    var year: Int
    
    init(date: Date, name: String, type: String, year: Int) {
        self.date = date
        self.name = name
        self.type = type
        self.year = year
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        self.id = "\(formatter.string(from: date))-\(name)"
    }
}
