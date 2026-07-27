---@class BoneTest : Wave
local BoneTest, super = Class(Wave)

function BoneTest:init()
    super.init(self)
    self.time = 30
end

function BoneTest:onStart()
    local arena = Game.battle.arena
    local _, center_y = arena:getCenter()
    local x_margin = 20

    self:spawnBullet(
        "sans_bone",
        arena:getLeft() + x_margin,
        center_y,
        40,
        "center"
    )
    self:spawnBullet(
        "pap_bone",
        arena:getRight() - x_margin,
        center_y,
        40,
        "center"
    )
end

return BoneTest
