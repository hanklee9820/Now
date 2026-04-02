import Foundation
import Testing
@testable import NowCore

struct EncryptedPreferencesTests {
    @Test
    func roundTripsSecureValuesWithoutUsingPlainUserDefaultsKey() {
        let sharedName = "NowCoreSecure.\(UUID().uuidString)"
        let encodedKey = EncryptedPreferences.encodedKey(for: "token", sharedName: sharedName)

        EncryptedPreferences.set("token", value: "plain-secret", sharedName: sharedName)

        #expect(EncryptedPreferences.get("token", defaultValue: "", sharedName: sharedName) == "plain-secret")
        #expect(NowPreferences.get("token", defaultValue: "", sharedName: sharedName).isEmpty)
        #expect(NowPreferences.get(encodedKey, defaultValue: "", sharedName: sharedName).isEmpty)

        EncryptedPreferences.clear(sharedName: sharedName)
    }
}
