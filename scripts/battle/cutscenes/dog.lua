return {
    ---@param cutscene BattleCutscene
    tell_joke = function(cutscene)
        cutscene:text(Game:loc("battle_dog_tell_joke_1"))

        cutscene:text(
            Game:loc("battle_dog_tell_joke_susie"),
            "nervous",
            "susie"
        )

        cutscene:text(
            Game:loc("battle_dog_tell_joke_ralsei"),
            "blush_pleased_open",
            "ralsei",
            {
                reactions = {
                    susie_reaction = {
                        Game:loc("battle_dog_tell_joke_susie_reaction"),
                        "right",
                        "bottom",
                        "nervous",
                        "susie"
                    }
                }
            }
        )

        -- These lines are narration, so they intentionally have no portrait.
        cutscene:setSpeaker(nil)
        cutscene:text(
            Game:loc("battle_dog_tell_joke_dog")
                .. "[wait:1s][sound:mus_rimshot]\n"
                .. Game:loc("battle_dog_tell_joke_inside")
        )
        cutscene:text(Game:loc("battle_dog_tell_joke_touch"))
    end,

    pet_party_special = function(cutscene)
        local dog = cutscene:getTarget()
        local shock_started = false

        cutscene:setSpeaker(nil)
        cutscene:text(Game:loc("battle_dog_pet_special"), {
            skip = false,
            advance = false,
            wait = false,
            functions = {
                dog_pet_special_shock = function()
                    dog:addMercy(100)
                    cutscene:setAnimation(dog, "shock")
                    shock_started = true
                end
            }
        })

        -- The localized text waits after the first line, then triggers the shock.
        cutscene:wait(function()
            return shock_started
        end)
        cutscene:wait(1)

        -- Keep both battler sprites shaking while the screen fades to white.
        dog.sprite:shake(4, 0, 0)
        dog.overlay_sprite:shake(4, 0, 0)
        local fade_out_done = cutscene:fadeOut(0.5, {
            color = COLORS.white,
            music = false
        })

        cutscene:wait(fade_out_done)

        -- Once pure white, automatically continue without waiting for input.
        Game.battle.battle_ui:clearEncounterText()
        dog.sprite:stopShake()
        dog.overlay_sprite:stopShake()
        cutscene:setAnimation(dog, "sleep")

        local fade_in_done = cutscene:fadeIn(0.75, {
            color = COLORS.white,
            music = false
        })
        cutscene:wait(fade_in_done)
        cutscene:text(Game:loc("battle_dog_pet_special_3"))
    end
}
