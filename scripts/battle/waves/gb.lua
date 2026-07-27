---@class GB : Wave
local GB, super = Class(Wave)

local FPS = 30
local SPIN_FRAME_COUNT = 27
local SPIN_LOOPS = 3
local SPIN_TIME = (SPIN_FRAME_COUNT * SPIN_LOOPS) / FPS
local ENTRY_TIME = 1
local WAIT_FRAMES = FPS
local CHARGE_FRAMES = 3
local BLAST_TIME = 45
local BLAST_WARMUP_FRAMES = 5
local BLAST_FADE_FRAMES = 20
local WHITE_FADE_TIME = 0.5
local WAVE_BUFFER = 1 / 3

local function getWaveTime()
    return SPIN_TIME
        + ENTRY_TIME
        + (WAIT_FRAMES / FPS)
        + (CHARGE_FRAMES / FPS)
        + ((BLAST_WARMUP_FRAMES + BLAST_TIME + BLAST_FADE_FRAMES) / FPS)
        + WAVE_BUFFER
end

local function playSpin(battler, loops_left, callback)
    battler:setAnimation({ "spin/spin", 1 / FPS, false }, function()
        if loops_left > 1 then
            playSpin(battler, loops_left - 1, callback)
        else
            callback()
        end
    end)
end

function GB:init()
    super.init(self)

    self.time = getWaveTime()
    self.dog = nil
    self.white_fx = nil
end

function GB:spawnBlaster()
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
    -- motion. The final point stays above the arena's top position.
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
            bullet.wait_time = WAIT_FRAMES
        end
    )

    if self.dog then
        self.dog:setAnimation("idle")
    end

    if self.white_fx then
        local white_fx = self.white_fx
        white_fx.amount = 1
        self.timer:tween(
            WHITE_FADE_TIME,
            white_fx,
            {amount = 0},
            "out-cubic",
            function()
                if self.dog and white_fx.parent == self.dog then
                    self.dog:removeFX(white_fx)
                end
                if self.white_fx == white_fx then
                    self.white_fx = nil
                end
            end
        )
    end
end

function GB:onStart()
    local attackers = self:getAttackers()
    self.dog = attackers[1]

    if not self.dog then
        self:spawnBlaster()
        return
    end

    self.white_fx = self.dog:addFX(ColorMaskFX({1, 1, 1}, 0), "gb_white")
    self.timer:tween(SPIN_TIME * (SPIN_LOOPS - 1) / SPIN_LOOPS, self.white_fx, {amount = 1}, "linear")

    playSpin(self.dog, SPIN_LOOPS, function()
        self:spawnBlaster()
    end)
end

function GB:onEnd()
    if self.white_fx and self.dog then
        self.dog:removeFX(self.white_fx)
        self.white_fx = nil
    end

    if self.dog then
        self.dog:setAnimation("idle")
    end
end

return GB
