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
    end
}
