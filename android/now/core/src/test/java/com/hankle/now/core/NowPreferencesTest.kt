package com.hankle.now.core

import com.hankle.now.core.storage.EncryptedPreferences
import com.hankle.now.core.storage.NowPreferences
import com.hankle.now.core.testing.InMemoryPreferencesStore
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class NowPreferencesTest {

    @After
    fun tearDown() {
        NowPreferences.resetForTesting()
        EncryptedPreferences.resetForTesting()
    }

    @Test
    fun `stores and retrieves primitive values from named stores`() {
        val backingStores = mutableMapOf<String, InMemoryPreferencesStore>()
        NowPreferences.installStoreFactoryForTesting { name ->
            backingStores.getOrPut(name ?: "default") { InMemoryPreferencesStore() }
        }

        NowPreferences.set("answer", 42, "session")
        NowPreferences.set("enabled", true, "session")
        NowPreferences.set("title", "Now", "session")

        assertEquals(42, NowPreferences.get("answer", 0, "session"))
        assertTrue(NowPreferences.get("enabled", false, "session"))
        assertEquals("Now", NowPreferences.get("title", "", "session"))
        assertTrue(NowPreferences.containsKey("answer", "session"))
    }

    @Test
    fun `encrypted preferences round trip values without exposing plain text in raw store`() {
        val store = InMemoryPreferencesStore()
        NowPreferences.installStoreFactoryForTesting { store }
        EncryptedPreferences.resetForTesting()

        EncryptedPreferences.set("token", "plain-secret", "secure")

        val rawValue = store.snapshot().values.single()
        assertNotEquals("plain-secret", rawValue)
        assertEquals("plain-secret", EncryptedPreferences.get("token", "", "secure"))
    }

    @Test
    fun `remove and clear delete stored values`() {
        NowPreferences.installStoreFactoryForTesting { InMemoryPreferencesStore() }

        NowPreferences.set("one", 1, "prefs")
        NowPreferences.set("two", 2, "prefs")
        NowPreferences.remove("one", "prefs")

        assertFalse(NowPreferences.containsKey("one", "prefs"))
        assertTrue(NowPreferences.containsKey("two", "prefs"))

        NowPreferences.clear("prefs")

        assertFalse(NowPreferences.containsKey("two", "prefs"))
    }
}
