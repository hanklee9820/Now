package com.hankle.now.hybrid.web

import org.junit.Assert.assertEquals
import org.junit.Test

class WilmarLocalSourceTest {

    @Test
    fun `prefixes relative paths with the local scheme`() {
        val source = WilmarLocalSource.create("web/demo/index.html")

        assertEquals("localx://web/demo/index.html", source.url)
    }

    @Test
    fun `keeps absolute urls unchanged`() {
        val source = WilmarLocalSource.create("https://example.com")

        assertEquals("https://example.com", source.url)
    }
}
