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
    end
}
