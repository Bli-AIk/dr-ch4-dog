---@class SansBone : BoneBullet
local BoneBullet = modRequire("scripts.battle.bonebullet")
local SansBone, super = Class(BoneBullet)

---@param x number # The X position of the bullet.
---@param y number # The Y position of the bullet.
---@param length? number # The full length of the bone in pixels.
---@param anchor? BoneAnchor # Which point of the bone is placed at x/y.
function SansBone:init(x, y, length, anchor)
    super.init(
        self,
        x,
        y,
        length,
        anchor,
        "bullets/s_top_0",
        "bullets/s_bottom_0",
        2,
        6
    )

    self.inv_timer = 0
    self.destroy_on_hit = false
end

return SansBone
