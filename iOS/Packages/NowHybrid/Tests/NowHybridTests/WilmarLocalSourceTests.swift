import Foundation
import Testing
@testable import NowHybrid

struct WilmarLocalSourceTests {
    @Test
    func buildsBundleAndSandboxUrls() {
        #expect(WilmarLocalSource.bundle("demo/index.html").url.absoluteString == "localx://bundle/demo/index.html")
        #expect(WilmarLocalSource.sandbox("cache/video.mp4").url.absoluteString == "localx://sandbox/cache/video.mp4")
    }
}
