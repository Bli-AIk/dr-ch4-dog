local PROP_FLOAT_RANGE = 4.5
local PROP_FLOAT_HALF_PERIOD = 1
local PROP_FLOAT_Y_OFFSET = -4
local PROP_X_OFFSET = 20

local function addFloatingProp(dog, texture, x, from_y, to_y)
    local prop = dog:addChild(Sprite(texture, x, from_y))
    prop:setOrigin(0.5, 0.5)
    prop:setScale(1)
    prop.layer = 1

    local function continueFloating(current_y, target_y)
        if not prop.parent then
            return
        end
        Game.battle.timer:tween(
            PROP_FLOAT_HALF_PERIOD,
            prop,
            {y = target_y},
            "in-out-sine",
            function()
                continueFloating(target_y, current_y)
            end
        )
    end

    continueFloating(from_y, to_y)
    return prop
end

local function addFloatingProps(dog)
    local center_y = dog.height / 2 + PROP_FLOAT_Y_OFFSET
    local top_y = center_y - PROP_FLOAT_RANGE
    local bottom_y = center_y + PROP_FLOAT_RANGE

    addFloatingProp(dog, "artifact", dog.width / 2 - PROP_X_OFFSET, top_y, bottom_y)
    addFloatingProp(dog, "sock", dog.width / 2 + PROP_X_OFFSET, bottom_y, top_y)
end

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
        addFloatingProps(dog)

        local fade_in_done = cutscene:fadeIn(0.75, {
            color = COLORS.white,
            music = false
        })
        cutscene:wait(fade_in_done)
        cutscene:text(Game:loc("battle_dog_pet_special_3"))
    end
}
