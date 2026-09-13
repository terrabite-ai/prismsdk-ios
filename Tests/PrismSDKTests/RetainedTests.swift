import Testing

@testable import PrismSDK

@Suite("Retained")
struct RetainedTests {

    private final class Token {}

    @Test("holds what it was given until replaced or cleared")
    func setAndClear() {
        let box = Retained<Token>()
        #expect(box.current == nil)

        let first = Token()
        box.set(first)
        #expect(box.current === first)

        let second = Token()
        box.set(second)
        #expect(box.current === second)

        box.set(nil)
        #expect(box.current == nil)
    }

    @Test("keeps its value alive")
    func retains() {
        let box = Retained<Token>()
        weak var weakToken: Token?

        do {
            let token = Token()
            weakToken = token
            box.set(token)
        }

        #expect(weakToken != nil)
        box.set(nil)
        #expect(weakToken == nil)
    }
}
