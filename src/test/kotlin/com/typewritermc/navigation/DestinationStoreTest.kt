package com.typewritermc.navigation

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import org.bukkit.entity.Player
import java.util.UUID

class DestinationStoreTest : FunSpec({
    test("set/get/clear stored destination") {
        val store = DestinationStore()
        val player = mockk<Player>()
        val uuid = UUID.randomUUID()
        every { player.uniqueId } returns uuid

        val pos = Position(World("minecraft:overworld"), 1.0, 2.0, 3.0, 0f, 0f)

        store.get(player, "dest") shouldBe null
        store.set(player, "dest", pos)
        store.get(player, "dest") shouldBe pos
        store.clear(player, "dest")
        store.get(player, "dest") shouldBe null
    }
})

