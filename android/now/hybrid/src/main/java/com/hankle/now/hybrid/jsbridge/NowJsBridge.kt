package com.hankle.now.hybrid.jsbridge

import com.hankle.now.hybrid.jsbridge.attribute.JsInterface
import com.hankle.now.hybrid.jsbridge.attribute.JsNativeClass
import com.hankle.now.hybrid.jsbridge.attribute.JsParam

@JsNativeClass(autoGenerate = true)
class NowJsBridge {
    @JsInterface
    fun saveStorage(@JsParam param: NowStorageParam) {
        require(param.key.isNotBlank()) { "key cannot be blank." }
        NowDomStorage.save(param.key, param.value, param.encrypted)
    }

    @JsInterface
    fun getStorage(@JsParam param: NowGetStorageParam): Any? {
        return NowDomStorage.getAny(param.key, param.encrypted)
    }

    @JsInterface
    fun removeStorage(@JsParam param: NowGetStorageParam) {
        NowDomStorage.remove(param.key, param.encrypted)
    }
}

class NowStorageParam {
    var key: String = ""
    var value: Any? = null
    var encrypted: Boolean = false
}

class NowGetStorageParam {
    var key: String = ""
    var encrypted: Boolean = false
}

