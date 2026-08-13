enum TableAlignment {
    case leading
    case center
    case trailing

    var cssValue: String {
        switch self {
        case .leading: "left"
        case .center: "center"
        case .trailing: "right"
        }
    }
}
