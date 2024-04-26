import SwiftUI

#if os(iOS)

protocol ColorProvider {
    var color: UIColor? { get }
}

struct AccentColorProvider: ColorProvider {
    var color: UIColor? {
        if #available(iOS 15, *) {
            return .tintColor
        } else if #available(iOS 14, *) {
            return UIColor(Color.accentColor)
        } else {
            return UIColor.systemBlue
        }
    }
}

struct TintShapeStyle: ColorProvider {
    var color: UIColor? {
        if #available(iOS 15, *) {
            return .tintColor
        } else if #available(iOS 14, *) {
            return UIColor(Color.accentColor)
        } else {
            return UIColor.systemBlue
        }
    }
}

struct ForegroundStyle: ColorProvider {
    var color: UIColor? { .label }
}


struct BackgroundStyle: ColorProvider {
    var color: UIColor? { .systemBackground }
}

struct UICachedDeviceRGBColor: ColorProvider {
    var color: UIColor?

    init(provider: Any) {
        let mirror = Mirror(reflecting: provider)
        let red = mirror.descendant("linearRed") as? Float ?? 1
        let green = mirror.descendant("linearGreen") as? Float ?? 1
        let blue = mirror.descendant("linearBlue") as? Float ?? 1
        let opacity = mirror.descendant("opacity") as? Float ?? 1
        let cgColor = CGColor(
            colorSpace: .init(name: CGColorSpace.genericRGBLinear) ?? CGColorSpaceCreateDeviceRGB(),
            components: [.init(red), .init(green), .init(blue), .init(opacity)]
        )
        color = cgColor.flatMap { UIColor(cgColor: $0) } ?? .label
    }
}

struct NamedColor: ColorProvider {
    var color: UIColor?

    init(provider: Any) {
        let mirror = Mirror(reflecting: provider)
        if let colorName = mirror.descendant("name") as? String {
            let bundle = mirror.descendant("bundle") as? Bundle
            color = UIColor(named: colorName, in: bundle, compatibleWith: nil)
        }
    }
}

struct UICGColor: ColorProvider {
    var color: UIColor?

    init(provider: Any) {
        if let color = provider as? UIColor {
            self.color = color
        }
    }
}

struct NSCFType: ColorProvider {
    var color: UIColor?

    init(provider: Any) {
        let isCGColor = CFGetTypeID(provider as CFTypeRef) == CGColor.typeID
        if isCGColor {
            color = UIColor(cgColor: provider as! CGColor)
        }
    }
}

struct UIDynamicCatalogSystemColor: ColorProvider {
    var color: UIColor?
}

struct DisplayP3: ColorProvider {
    var color: UIColor?

    init(provider: Any) {
        let mirror = Mirror(reflecting: provider)
        let red = mirror.descendant("red") as? CGFloat ?? 1
        let green = mirror.descendant("green") as? CGFloat ?? 1
        let blue = mirror.descendant("blue") as? CGFloat ?? 1
        let opacity = mirror.descendant("opacity") as? Float ?? 1
        let cgColor = CGColor(
            colorSpace: .init(name: CGColorSpace.displayP3) ?? CGColorSpaceCreateDeviceRGB(),
            components: [.init(red), .init(green), .init(blue)]
        )
        color = cgColor.flatMap { UIColor(cgColor: $0).withAlphaComponent(.init(opacity)) } ?? .label
    }
}

struct OffsetShapeStyle<T: ColorProvider>: ColorProvider {
    var color: UIColor?
}

extension OffsetShapeStyle<SystemColorsStyle> {
    init(provider: Any) {
        let mirror = Mirror(reflecting: provider)
        let offset = mirror.descendant("offset") as? Int ?? 0
        switch offset {
        case 1: color = .secondaryLabel
        case 2: color = .tertiaryLabel
        case 3: color = .quaternaryLabel
        default: color = .label
        }
    }
}

struct SelectionShapeStyle: ColorProvider {
    var color: UIColor? { nil }
}


struct SystemColorsStyle: ColorProvider {
    let style: SystemColorType.Style
    var color: UIColor? { style.color }
}

struct SystemColorType: ColorProvider {
    enum Style: String {
        case primary, secondary
        case black, white, gray, clear
        case blue, brown, cyan, green
        case indigo, mint, orange, pink
        case purple, red, teal, yellow

        var color: UIColor {
            switch self {
            case .black: return .black
            case .white: return .white
            case .primary: return .label
            case .secondary: return .secondaryLabel
            case .blue: return .systemBlue
            case .brown: return .systemBrown
            case .clear: return .clear
            case .cyan:
                if #available(iOS 15, *) {
                    return .systemCyan
                } else {
                    return .systemTeal
                }
            case .gray: return .systemGray
            case .green: return .systemGreen
            case .indigo: return .systemIndigo
            case .mint:
                if #available(iOS 15, *) {
                    return .systemMint
                } else {
                    return .systemTeal
                }
            case .orange: return .systemOrange
            case .pink: return .systemPink
            case .purple: return .systemPurple
            case .red: return .systemRed
            case .teal: return .systemTeal
            case .yellow: return .systemYellow
            }
        }
    }

    let style: Style
    var color: UIColor? { style.color }
}

func colorProvider(from values: EnvironmentValues) -> Any? {
    let mirror = Mirror(reflecting: values)
    guard let provider = mirror.descendant(
        "_plist", "elements", "some", "value",
        "some", "storage", "box", "base"
    ) else {
        return nil
    }
    return provider
}

func isAccentColor(provider: Any) -> Bool {
    String(describing: type(of: provider)) == String(describing: AccentColorProvider.self)
}

func resolveColor(_ values: EnvironmentValues) -> UIColor? {
    guard let provider = colorProvider(from: values) else { return nil }
    return resolveColorProvider(provider)?.color
}

func resolveColorProvider(_ provider: Any) -> ColorProvider? {
    switch String(describing: type(of: provider)) {
    case String(describing: SelectionShapeStyle.self):
        return SelectionShapeStyle()
    case String(describing: AccentColorProvider.self):
        return AccentColorProvider()
    case String(describing: TintShapeStyle.self):
        return TintShapeStyle()
    case String(describing: ForegroundStyle.self):
        return ForegroundStyle()
    case String(describing: BackgroundStyle.self):
        return BackgroundStyle()
    case String(describing: OffsetShapeStyle<SystemColorsStyle>.self):
        return OffsetShapeStyle<SystemColorsStyle>(provider: provider)
    case String(describing: SystemColorType.self):
        return SystemColorType(style: .init(rawValue: "\(provider)") ?? .primary)
    case String(describing: SystemColorsStyle.self):
        return SystemColorsStyle(style: .init(rawValue: "\(provider)") ?? .primary)
    case String(describing: UICachedDeviceRGBColor.self):
        return UICachedDeviceRGBColor(provider: provider)
    case String(describing: UIDynamicCatalogSystemColor.self):
        return UIDynamicCatalogSystemColor()
    case String(describing: DisplayP3.self):
        return DisplayP3(provider: provider)
    case "Resolved":
        return UICachedDeviceRGBColor(provider: provider)
    case String(describing: NamedColor.self):
        return NamedColor(provider: provider)
    case String(describing: UICGColor.self):
        return UICGColor(provider: provider)
    case "__\(String(describing: NSCFType.self))":
        return NSCFType(provider: provider)
    default:
        print("Unhandled color provider: \(String(describing: type(of: provider)))")
        return nil
    }
}

func printMirror(_ value: Any) {
    let mirror = Mirror(reflecting: value)
    for child in mirror.children {
        print(child)
    }
}
#endif
