package com.typewritermc.navigation

import com.typewritermc.core.entries.ref
import com.typewritermc.core.interaction.context as twContext
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.navigation.entries.action.ClearStoredDestinationActionEntry
import com.typewritermc.navigation.entries.action.SetStoredDestinationActionEntry
import com.typewritermc.navigation.entries.variables.StoredDestinationVariableEntry
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import io.mockk.every
import org.bukkit.entity.Player
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import java.util.UUID

class SetClearStoredDestinationActionTest : FunSpec({
    beforeTest {
        startKoin {
            modules(
                module {
                    single { DestinationStore() }
                }
            )
        }
    }

    afterTest {
        stopKoin()
    }

    test("set action stores destination into selected variable slot") {
        val store = org.koin.java.KoinJavaComponent.get<DestinationStore>(DestinationStore::class.java)
        val player = mockk<Player>()
        every { player.uniqueId } returns UUID.randomUUID()

        val destVar = StoredDestinationVariableEntry(id = "dest")
        val position = Position(World("minecraft:overworld"), 10.0, 20.0, 30.0, 0f, 0f)

        val action = SetStoredDestinationActionEntry(
            destination = destVar.ref(),
            position = ConstVar(position)
        )

        val trigger = ActionTrigger(player, twContext(), action)
        action.run { trigger.execute() }

        store.get(player, "dest") shouldBe position
    }

    test("clear action removes destination") {
        val store = org.koin.java.KoinJavaComponent.get<DestinationStore>(DestinationStore::class.java)
        val player = mockk<Player>()
        every { player.uniqueId } returns UUID.randomUUID()
        val destVar = StoredDestinationVariableEntry(id = "dest")
        val position = Position(World("minecraft:overworld"), 10.0, 20.0, 30.0, 0f, 0f)
        store.set(player, "dest", position)

        val action = ClearStoredDestinationActionEntry(destination = destVar.ref())
        val trigger = ActionTrigger(player, twContext(), action)
        action.run { trigger.execute() }

        store.get(player, "dest") shouldBe null
    }
})

