package com.hankle.now.core.file

import com.hankle.now.core.service.WilmarServiceLocator

object NowFileSystem {
    val cachePath: String
        get() = WilmarServiceLocator.instance.getService<IFileSystemService>().cachePath

    val appDataPath: String
        get() = WilmarServiceLocator.instance.getService<IFileSystemService>().appDataPath
}

