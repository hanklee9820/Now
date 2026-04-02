package com.hankle.now.hybrid.jsbridge.dto

open class HybResponse(
    val code: Int,
    val message: String,
) {
    companion object {
        fun succeed(oldRes: Boolean = false): HybResponse {
            return HybResponse(
                code = if (oldRes) ResponseCode.OldSucceed.value else ResponseCode.Succeed.value,
                message = "成功！",
            )
        }

        fun <T> succeed(data: T, oldRes: Boolean = false): HybResponseData<T> {
            return HybResponseData(
                code = if (oldRes) ResponseCode.OldSucceed.value else ResponseCode.Succeed.value,
                message = "成功！",
                data = data,
            )
        }

        fun error(errorMessage: String, oldRes: Boolean = false): HybResponse {
            return HybResponse(
                code = if (oldRes) ResponseCode.OldError.value else ResponseCode.Error.value,
                message = errorMessage,
            )
        }

        fun exception(exception: Throwable, oldRes: Boolean = false): HybResponse {
            return HybResponse(
                code = if (oldRes) ResponseCode.OldException.value else ResponseCode.Exception.value,
                message = exception.message ?: "Unknown bridge exception",
            )
        }
    }
}

class HybResponseData<T>(
    code: Int,
    message: String,
    val data: T,
) : HybResponse(code, message)

enum class ResponseCode(val value: Int) {
    Succeed(200),
    Error(500),
    Exception(401),
    OldSucceed(0),
    OldError(1),
    OldException(2),
}
