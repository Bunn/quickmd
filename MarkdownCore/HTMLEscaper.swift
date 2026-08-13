import Foundation

enum HTMLEscaper {
    static func text(_ value: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(value.count)

        for character in value {
            switch character {
            case "&": escaped += "&amp;"
            case "<": escaped += "&lt;"
            case ">": escaped += "&gt;"
            case "\"": escaped += "&quot;"
            case "'": escaped += "&#39;"
            default: escaped.append(character)
            }
        }

        return escaped
    }
}
