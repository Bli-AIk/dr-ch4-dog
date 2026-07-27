---@class GB : Wave
local GB, super = Class(Wave)

local ENTRY_TIME = 1
local WAIT_TIME = 1
local BLAST_TIME = 45

function GB:init()
    super.init(self)

    -- Give the cannon enough time to finish entering, firing, and fading out.
    self.time = 5
end

function GB:onStart()
    local arena = Game.battle.arena
    local center_x = arena:getCenter()
    local top_y = arena:getTop() + 18
    local start_y = -120
    local final_y = top_y - 50

    local bullet = self:spawnBullet(
        "gaster_blaster",
        center_x,
        start_y,
        90,
        center_x,
        start_y,
        0,
        math.huge,
        BLAST_TIME,
        true
    )

    -- Skip the library's linear approach and let the wave own the entry
    -- motion. The final point is 100 pixels above the arena's top position.
    bullet.state = 1
    bullet.target_x = center_x
    bullet.target_y = start_y
    bullet.target_rot = 0

    self.timer:tween(
        ENTRY_TIME,
        bullet,
        {y = final_y, rotation = 0},
        "out-cubic",
        function()
            bullet.wait_time = WAIT_TIME
        end
    )
end

return GB
