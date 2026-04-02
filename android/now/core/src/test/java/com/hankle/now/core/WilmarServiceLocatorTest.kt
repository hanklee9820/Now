package com.hankle.now.core

import com.hankle.now.core.file.IFileSystemService
import com.hankle.now.core.file.NowFileSystem
import com.hankle.now.core.service.WilmarServiceLocator
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test

class WilmarServiceLocatorTest {

    @After
    fun tearDown() {
        WilmarServiceLocator.resetForTesting()
    }

    @Test
    fun `returns registered services by type`() {
        val fileSystemService = object : IFileSystemService {
            override val cachePath: String = "/tmp/cache"
            override val appDataPath: String = "/tmp/data"
        }

        WilmarServiceLocator.init(mapOf(IFileSystemService::class to fileSystemService))

        assertEquals(fileSystemService, WilmarServiceLocator.instance.getService<IFileSystemService>())
        assertEquals("/tmp/cache", NowFileSystem.cachePath)
        assertEquals("/tmp/data", NowFileSystem.appDataPath)
    }
}
