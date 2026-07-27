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

return PapBone
