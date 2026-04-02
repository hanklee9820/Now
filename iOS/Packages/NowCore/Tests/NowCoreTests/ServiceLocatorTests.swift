import Foundation
import Testing
@testable import NowCore

struct ServiceLocatorTests {
    @Test
    func registersAndReturnsServices() {
        let locator = WilmarServiceLocator()
        let value = TestService(value: "registered")

        locator.register(TestService.self, service: value)

        #expect(locator.getService(TestService.self)?.value == "registered")
    }

    @Test
    func createsWritableAppDataPath() throws {
        let directory = URL(fileURLWithPath: NowFileSystem.appDataPath, isDirectory: true)
        #expect(!directory.path.isEmpty)
    }
}

private struct TestService: Equatable {
    let value: String
}
