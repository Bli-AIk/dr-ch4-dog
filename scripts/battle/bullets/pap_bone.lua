---@class PapBone : BoneBullet
local BoneBullet = modRequire("scripts.battle.bonebullet")
local PapBone, super = Class(BoneBullet)

---@param x number # The X position of the bullet.
---@param y number # The Y position of the bullet.
---@param length? number # The full length of the bone in pixels.
---@param anchor? BoneAnchor # Which point of the bone is placed at x/y.
---@param direction? number # Optional movement direction, in radians.
---@param speed? number # Optional movement speed, in pixels per frame at 30FPS.
function PapBone:init(x, y, length, anchor, direction, speed)
    super.init(
        self,
        x,
        y,
        length,
        anchor,
        direction,
        speed,
        "bullets/p_top_0",
        "bullets/p_bottom_0",
        4,
        5
    )
end

return PapBone
