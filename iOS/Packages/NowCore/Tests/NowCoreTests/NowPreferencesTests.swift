import Foundation
import Testing
@testable import NowCore

struct NowPreferencesTests {
    @Test
    func storesValuesBySharedSuite() {
        let sharedName = "NowCoreTests.\(UUID().uuidString)"

        NowPreferences.set("greeting", value: "hello", sharedName: sharedName)
        NowPreferences.set("enabled", value: true, sharedName: sharedName)
        NowPreferences.set("count", value: 7, sharedName: sharedName)

        #expect(NowPreferences.get("greeting", defaultValue: "", sharedName: sharedName) == "hello")
        #expect(NowPreferences.get("enabled", defaultValue: false, sharedName: sharedName))
        #expect(NowPreferences.get("count", defaultValue: 0, sharedName: sharedName) == 7)
        #expect(NowPreferences.containsKey("greeting", sharedName: sharedName))

        NowPreferences.clear(sharedName: sharedName)
    }

    @Test
    func removesAndClearsValues() {
        let sharedName = "NowCoreTests.\(UUID().uuidString)"

        NowPreferences.set("first", value: "one", sharedName: sharedName)
        NowPreferences.set("second", value: "two", sharedName: sharedName)
        NowPreferences.remove("first", sharedName: sharedName)

        #expect(!NowPreferences.containsKey("first", sharedName: sharedName))
        #expect(NowPreferences.containsKey("second", sharedName: sharedName))

        NowPreferences.clear(sharedName: sharedName)

        #expect(!NowPreferences.containsKey("second", sharedName: sharedName))
    }
}
