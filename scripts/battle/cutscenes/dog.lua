return {
    ---@param cutscene BattleCutscene
    tell_joke = function(cutscene)
        cutscene:text(Game:loc("* Everyone came up with a terrible pun...[wait:5]", "battle_dog_tell_joke_1"))

        cutscene:text(
            Game:loc("* Uh...[wait:5]\n* Why can't a dog be a singer?", "battle_dog_tell_joke_susie"),
            "nervous",
            "susie"
        )

        cutscene:text(
            Game:loc("* Because it always PAWS halfway through![wait:5][react:susie_reaction]", "battle_dog_tell_joke_ralsei"),
            "blush_pleased_open",
            "ralsei",
            {
                reactions = {
                    susie_reaction = {
                        Game:loc("...", "battle_dog_tell_joke_susie_reaction"),
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
