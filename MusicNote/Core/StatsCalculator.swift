import UIKit


// MARK: - Pastel Accuracy Colors
private func pastelAccuracyColor(_ accuracy: Double) -> UIColor {
    switch accuracy {
    case ..<0.60:
        return UIColor(red: 1.00, green: 0.82, blue: 0.82, alpha: 1.0) // pastel red
    case 0.60..<0.90:
        return UIColor(red: 1.00, green: 0.94, blue: 0.78, alpha: 1.0) // pastel yellow
    default:
        return UIColor(red: 0.80, green: 0.93, blue: 0.85, alpha: 1.0) // pastel green
    }
}

// MARK: - Pastel Accuracy Border Color
private func pastelAccuracyBorderColor(_ accuracy: Double) -> UIColor {
    switch accuracy {
    case ..<0.60:
        return UIColor(red: 0.95, green: 0.60, blue: 0.60, alpha: 1.0) // darker pastel red
    case 0.60..<0.90:
        return UIColor(red: 0.92, green: 0.82, blue: 0.45, alpha: 1.0) // darker pastel yellow
    default:
        return UIColor(red: 0.45, green: 0.78, blue: 0.60, alpha: 1.0) // darker pastel green
    }
}
