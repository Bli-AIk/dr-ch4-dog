---@class PapBone : BoneBullet
local BoneBullet = modRequire("scripts.battle.bonebullet")
local PapBone, super = Class(BoneBullet)

---@param x number # The X position of the bullet.
---@param y number # The Y position of the bullet.
---@param length? number # The full length of the bone in pixels.
---@param anchor? BoneAnchor # Which point of the bone is placed at x/y.
function PapBone:init(x, y, length, anchor)
    super.init(
        self,
        x,
        y,
        length,
        anchor,
        "bullets/p_top_0",
        "bullets/p_bottom_0",
        4,
        5
    )

    self.damage = 66
end

--- 保底：不管打中谁，都打不死人——最多打到剩 1 点血
function PapBone:getDamage()
    local min_hp = math.huge
    for _, battler in ipairs(Game.battle.party) do
        min_hp = math.min(min_hp, battler.chara:getHealth())
    end
    if min_hp <= 1 then
        return 0
    end
    return math.min(self.damage, min_hp - 1)
end

return PapBone
