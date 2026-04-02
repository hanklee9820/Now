import Foundation
import Testing
@testable import NowCore

struct RuntimeTests {
    @Test
    func hopsBackToMainThread() async {
        let didRunOnMain = await withCheckedContinuation { continuation in
            let thread = Thread {
                WilmarMainThread.beginInvokeOnMainThread {
                    continuation.resume(returning: Thread.isMainThread)
                }
            }
            thread.start()
        }
        #expect(didRunOnMain)
    }

    @Test
    func returnsInjectedConnectivityState() {
        NowConnectivity.provider = TestConnectivityProvider(access: .internet)
        #expect(NowConnectivity.networkAccess == .internet)
        NowConnectivity.provider = DefaultConnectivityProvider()
    }
}

private struct TestConnectivityProvider: ConnectivityProvider {
    let access: NowNetworkAccess

    func currentAccess() -> NowNetworkAccess {
        access
    }
}
