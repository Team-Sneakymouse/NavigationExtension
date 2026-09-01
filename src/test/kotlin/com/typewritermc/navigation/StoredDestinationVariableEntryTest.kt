package com.typewritermc.navigation

import com.google.gson.Gson
import com.google.gson.JsonParser
import com.typewritermc.core.utils.Generic
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.navigation.entries.variables.StoredDestinationVariableEntry
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import io.mockk.every
import org.bukkit.entity.Player
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import org.koin.core.qualifier.named
import java.util.UUID

class StoredDestinationVariableEntryTest : FunSpec({
    beforeTest {
        startKoin {
            modules(
                module {
                    single { DestinationStore() }
                    single(named("dataSerializer")) { Gson() }
                }
            )
        }
    }

    afterTest {
        stopKoin()
    }

    test("returns default when not stored") {
        val player = mockk<Player>()
        every { player.uniqueId } returns UUID.randomUUID()
        val entry = StoredDestinationVariableEntry(id = "dest")
        val ctx = VarContext(
            player = player,
            data = Generic(
                JsonParser.parseString(
                    """{"default":{"world":{"identifier":"minecraft:overworld"},"x":1.0,"y":2.0,"z":3.0,"yaw":0.0,"pitch":0.0}}"""
                )
            ),
            klass = Position::class,
            interactionContext = null
        )

        entry.get(ctx) shouldBe Position(World("minecraft:overworld"), 1.0, 2.0, 3.0, 0f, 0f)
    }

    test("returns stored value when present") {
        val player = mockk<Player>()
        every { player.uniqueId } returns UUID.randomUUID()
        val entry = StoredDestinationVariableEntry(id = "dest")
        val store = org.koin.java.KoinJavaComponent.get<DestinationStore>(DestinationStore::class.java)
        val stored = Position(World("minecraft:overworld"), 5.0, 6.0, 7.0, 0f, 0f)
        store.set(player, "dest", stored)

        val ctx = VarContext(
            player = player,
            data = Generic(
                JsonParser.parseString(
                    """{"default":{"world":{"identifier":"minecraft:overworld"},"x":1.0,"y":2.0,"z":3.0,"yaw":0.0,"pitch":0.0}}"""
                )
            ),
            klass = Position::class,
            interactionContext = null
        )

        entry.get(ctx) shouldBe stored
    }

    test("returns stored value when default in variable data has empty world") {
        val player = mockk<Player>()
        every { player.uniqueId } returns UUID.randomUUID()
        val entry = StoredDestinationVariableEntry(id = "dest")
        val store = org.koin.java.KoinJavaComponent.get<DestinationStore>(DestinationStore::class.java)
        val stored = Position(World("minecraft:overworld"), 5.0, 6.0, 7.0, 0f, 0f)
        store.set(player, "dest", stored)

        val ctx = VarContext(
            player = player,
            data = Generic(
                JsonParser.parseString(
                    """{"default":{"world":"","x":0,"y":0,"z":0,"yaw":0,"pitch":0}}"""
                )
            ),
            klass = Position::class,
            interactionContext = null
        )

        entry.get(ctx) shouldBe stored
    }
})

