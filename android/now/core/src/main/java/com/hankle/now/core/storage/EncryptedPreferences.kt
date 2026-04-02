package com.hankle.now.core.storage

import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.time.Instant
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

object EncryptedPreferences {
    private const val DEFAULT_PREF_NAME = "NowEncryptedPreferences"
    private val encryptKey = "_sfa_pf_key_baesed_on_aes_".padEnd(32).toByteArray(StandardCharsets.UTF_8)
    private val encryptVector = "vec_by_sfa_pref_".padEnd(16).toByteArray(StandardCharsets.UTF_8)

    fun containsKey(key: String, sharedName: String? = null): Boolean =
        NowPreferences.containsKey(encodeKey(key), sharedName ?: DEFAULT_PREF_NAME)

    fun remove(key: String, sharedName: String? = null) {
        NowPreferences.remove(encodeKey(key), sharedName ?: DEFAULT_PREF_NAME)
    }

    fun clear(sharedName: String? = null) {
        NowPreferences.clear(sharedName ?: DEFAULT_PREF_NAME)
    }

    fun set(key: String, value: String, sharedName: String? = null) =
        saveEncrypted(key, value, sharedName)

    fun get(key: String, defaultValue: String, sharedName: String? = null): String =
        readDecrypted(key, sharedName) ?: defaultValue

    fun set(key: String, value: Boolean, sharedName: String? = null) =
        saveEncrypted(key, value.toString(), sharedName)

    fun get(key: String, defaultValue: Boolean, sharedName: String? = null): Boolean =
        readDecrypted(key, sharedName)?.toBooleanStrictOrNull() ?: defaultValue

    fun set(key: String, value: Int, sharedName: String? = null) =
        saveEncrypted(key, value.toString(), sharedName)

    fun get(key: String, defaultValue: Int, sharedName: String? = null): Int =
        readDecrypted(key, sharedName)?.toIntOrNull() ?: defaultValue

    fun set(key: String, value: Long, sharedName: String? = null) =
        saveEncrypted(key, value.toString(), sharedName)

    fun get(key: String, defaultValue: Long, sharedName: String? = null): Long =
        readDecrypted(key, sharedName)?.toLongOrNull() ?: defaultValue

    fun set(key: String, value: Float, sharedName: String? = null) =
        saveEncrypted(key, value.toString(), sharedName)

    fun get(key: String, defaultValue: Float, sharedName: String? = null): Float =
        readDecrypted(key, sharedName)?.toFloatOrNull() ?: defaultValue

    fun set(key: String, value: Double, sharedName: String? = null) =
        saveEncrypted(key, value.toString(), sharedName)

    fun get(key: String, defaultValue: Double, sharedName: String? = null): Double =
        readDecrypted(key, sharedName)?.toDoubleOrNull() ?: defaultValue

    fun set(key: String, value: Instant, sharedName: String? = null) =
        saveEncrypted(key, value.toString(), sharedName)

    fun get(key: String, defaultValue: Instant, sharedName: String? = null): Instant =
        readDecrypted(key, sharedName)?.let {
            runCatching { Instant.parse(it) }.getOrNull()
        } ?: defaultValue

    internal fun resetForTesting() = Unit

    private fun saveEncrypted(key: String, value: String, sharedName: String?) {
        NowPreferences.set(encodeKey(key), encrypt(value), sharedName ?: DEFAULT_PREF_NAME)
    }

    private fun readDecrypted(key: String, sharedName: String?): String? {
        val encrypted = NowPreferences.get(encodeKey(key), "", sharedName ?: DEFAULT_PREF_NAME)
        return encrypted.takeIf { it.isNotEmpty() }?.let(::decrypt)
    }

    private fun encodeKey(key: String): String {
        val digest = MessageDigest.getInstance("MD5").digest(key.toByteArray(StandardCharsets.UTF_8))
        return Base64.getEncoder().encodeToString(digest)
    }

    private fun encrypt(value: String): String {
        val cipher = Cipher.getInstance("AES/CBC/PKCS5Padding")
        cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(encryptKey, "AES"), IvParameterSpec(encryptVector))
        return Base64.getEncoder().encodeToString(cipher.doFinal(value.toByteArray(StandardCharsets.UTF_8)))
    }

    private fun decrypt(value: String): String {
        val cipher = Cipher.getInstance("AES/CBC/PKCS5Padding")
        cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(encryptKey, "AES"), IvParameterSpec(encryptVector))
        val decoded = Base64.getDecoder().decode(value)
        return String(cipher.doFinal(decoded), StandardCharsets.UTF_8)
    }
}

