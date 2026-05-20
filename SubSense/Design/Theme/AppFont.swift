import SwiftUI

extension Font {
    static let display     = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let appTitle    = Font.system(.title,      design: .rounded, weight: .semibold)
    static let appTitle2   = Font.system(.title2,                       weight: .semibold)
    static let appBody     = Font.system(.body,                         weight: .regular)
    static let appCallout  = Font.system(.callout,                      weight: .medium)
    static let appFootnote = Font.system(.footnote,                     weight: .regular)
    static let appCaption  = Font.system(.caption2,                     weight: .medium)
}
