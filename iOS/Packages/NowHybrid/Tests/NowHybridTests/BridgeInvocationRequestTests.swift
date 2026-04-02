import Testing
@testable import NowHybrid

struct BridgeInvocationRequestTests {
    @Test
    func parsesStructuredPayloads() {
        let request = BridgeInvocationRequest.from(
            eventName: "echoMessage",
            payload: #"{"callbackId":"window.cb","params":"hello"}"#
        )

        #expect(request.methodName == "echoMessage")
        #expect(request.paramData == "hello")
        #expect(request.callbackId == "window.cb")
        #expect(!request.oldVersion)
    }

    @Test
    func parsesLegacyPayloads() {
        let request = BridgeInvocationRequest.from(
            eventName: "native:legacyBridge?42",
            payload: "legacyCallback"
        )

        #expect(request.methodName == "legacyBridge")
        #expect(request.paramData == "42")
        #expect(request.callbackId == "legacyCallback")
        #expect(request.oldVersion)
    }
}
