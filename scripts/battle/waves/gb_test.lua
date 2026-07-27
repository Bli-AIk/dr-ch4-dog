---@class GBTest : Wave
local GBTest, super = Class(Wave)

function GBTest:init()
    super.init(self)
    self.time = 8
end

function GBTest:onStart()
    local arena = Game.battle.arena
    local center_x, center_y = arena:getCenter()
    local arena_top = arena:getTop()
    local arena_right = arena:getRight()

    -- A vertical shot from above. The beam stays active long enough to show
    -- both frame damage and repeated graze TP.
    self:spawnBullet(
        "gaster_blaster",
        center_x,
        arena_top - 80,
        0,
        center_x,
        arena_top + 18,
        0,
        45,
        45,
        true
    )

    -- Follow with a horizontal shot to demonstrate rotation and exit motion.
    self.timer:after(2.5, function()
        self:spawnBullet(
            "gaster_blaster",
            arena_right + 80,
            center_y,
            90,
            arena_right - 18,
            center_y,
            90,
            45,
            45,
            true
        )
    end)
end

return GBTest
