//
//  FormatterHelper.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation

public class FormatterHelper {
    public static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    public static func formatNumber(_ num: NSNumber) -> String {
        if let str = numberFormatter.string(from: num) {
            return str
        }
        return ""
    }
    
    public static func formatDouble(_ num: Double) -> String {
        return formatNumber(num as NSNumber)
    }
}
