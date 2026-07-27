---@class PartyBattler
local PartyBattler, super = HookSystem.hookScript(PartyBattler)

function PartyBattler:setAnimation(animation, callback)
    if animation == "battle/idle"
        and self.chara
        and self.chara.id == "susie"
        and Game.battle
        and Game.battle.encounter
        and Game.battle.encounter.id == "dog"
    then
        self.actor.offsets["battle/idle_happy"] = self.actor.offsets["battle/idle"] or { 0, 0 }
        animation = { "battle/idle_happy", 1 / 6, true }
    end

    return super.setAnimation(self, animation, callback)
end

return PartyBattler
