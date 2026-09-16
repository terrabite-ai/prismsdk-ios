import Foundation
import PrismEnrich

/// How much history places are inferred from. Older stays are forgotten.
public enum PrismPlaceRetention: String, Codable, Sendable {
    case oneMonth = "ONE_MONTH"
    case threeMonths = "THREE_MONTHS"
    case sixMonths = "SIX_MONTHS"

    var core: EnrichRetention {
        switch self {
        case .oneMonth: return .oneMonth
        case .threeMonths: return .threeMonths
        case .sixMonths: return .sixMonths
        }
    }

    init(_ r: EnrichRetention) {
        switch r {
        case .oneMonth: self = .oneMonth
        case .threeMonths: self = .threeMonths
        case .sixMonths: self = .sixMonths
        @unknown default: self = .threeMonths
        }
    }
}

/// Places configuration. Setting it on `PrismConfig.enrich` turns place
/// inference on; everything runs on the device and nothing leaves it.
public struct PrismEnrichConfig: Equatable, Sendable {
    public var retention: PrismPlaceRetention

    public init(retention: PrismPlaceRetention = .threeMonths) {
        self.retention = retention
    }

    public func withRetention(_ retention: PrismPlaceRetention) -> PrismEnrichConfig {
        var copy = self
        copy.retention = retention
        return copy
    }

    var core: EnrichConfig { EnrichConfig(retention: retention.core) }
}
