import LocalSDKCore
import Testing

@testable import PrismSDK

@Suite("PrismConfig mapping")
struct PrismConfigMappingTests {

    @Test("defaults are the engine's defaults")
    func defaults() {
        let prism = PrismConfig().core
        let engine = Config()

        #expect(prism.trackingMode == engine.trackingMode)
        #expect(prism.allowMockLocation == engine.allowMockLocation)
        #expect(prism.horizontalAccuracyThreshold == engine.horizontalAccuracyThreshold)
        #expect(prism.backgroundLocationEnabled == engine.backgroundLocationEnabled)
    }

    @Test("every field reaches the engine config")
    func memberwise() {
        let core = PrismConfig(
            trackingMode: .efficient,
            allowMockLocation: true,
            horizontalAccuracyThreshold: 35,
            backgroundLocationEnabled: false
        ).core

        #expect(core.trackingMode == .efficient)
        #expect(core.allowMockLocation == true)
        #expect(core.horizontalAccuracyThreshold == 35)
        #expect(core.backgroundLocationEnabled == false)
    }

    @Test("builders produce the same value as the memberwise initialiser")
    func builders() {
        let built = PrismConfig()
            .withTrackingMode(.standard)
            .withAllowMockLocation(true)
            .withHorizontalAccuracyThreshold(50)
            .withBackgroundLocationEnabled(false)

        let direct = PrismConfig(
            trackingMode: .standard,
            allowMockLocation: true,
            horizontalAccuracyThreshold: 50,
            backgroundLocationEnabled: false
        )

        #expect(built == direct)
    }

    @Test("builders do not mutate the value they were called on")
    func buildersAreValueSemantics() {
        let original = PrismConfig()
        _ = original.withTrackingMode(.efficient)

        #expect(original.trackingMode == .precise)
    }

    // MARK: - Objective-C

    @Test("the Objective-C config maps each tracking mode string",
          arguments: [("PRECISE", PrismTrackingMode.precise),
                      ("STANDARD", .standard),
                      ("EFFICIENT", .efficient)])
    func objcTrackingMode(string: String, expected: PrismTrackingMode) {
        let config = PrismConfigObjC()
        config.trackingMode = string

        #expect(config.config.trackingMode == expected)
    }

    @Test("an unrecognised tracking mode string falls back to the default rather than failing")
    func objcUnrecognisedTrackingMode() {
        let config = PrismConfigObjC()
        config.trackingMode = "TURBO"

        #expect(config.config.trackingMode == PrismConfig().trackingMode)
    }

    @Test("the Objective-C config carries the other fields")
    func objcOtherFields() {
        let config = PrismConfigObjC()
        config.allowMockLocation = true
        config.horizontalAccuracyThreshold = 75
        config.backgroundLocationEnabled = false

        let mapped = config.config
        #expect(mapped.allowMockLocation == true)
        #expect(mapped.horizontalAccuracyThreshold == 75)
        #expect(mapped.backgroundLocationEnabled == false)
    }
}
