---@class GB : Wave
local GB, super = Class(Wave)

-- 游戏使用的帧率
local FPS = 30

-- Dog spin 动画的帧数
local SPIN_FRAME_COUNT = 27
-- Dog spin 动画的循环次数
local SPIN_LOOPS = 3
-- Dog spin 动画的总时长
local SPIN_TIME = (SPIN_FRAME_COUNT * SPIN_LOOPS) / FPS

-- 圆形效果的持续时长
local CIRCLE_TIME = SPIN_TIME * (SPIN_LOOPS - 1) / SPIN_LOOPS
-- 圆形效果出现时的半径
local CIRCLE_INITIAL_RADIUS = 300
-- 圆形效果开始持续缩小时的半径
local CIRCLE_START_RADIUS = 100
-- 圆形效果的最小半径
local CIRCLE_MIN_RADIUS = 0
-- 圆形效果从大变小的时长
local CIRCLE_INTRO_TIME = 9 / FPS
-- 圆形绘制使用的分段数
local CIRCLE_SEGMENTS = 96

-- GB 滑入战斗框的时长
local ENTRY_TIME = 1
-- GB 发射前的等待帧数
local WAIT_FRAMES = FPS / 2
-- GB 发射前的蓄力帧数
local CHARGE_FRAMES = 3

-- GB 光束的持续时长
local BLAST_TIME = 45
-- GB 光束的预热帧数
local BLAST_WARMUP_FRAMES = 5
-- GB 光束的消散帧数
local BLAST_FADE_FRAMES = 20

-- Dog 白色覆盖的褪去时长
local WHITE_FADE_TIME = 0.5
-- 回合结束前的额外缓冲时长
local WAVE_BUFFER = 1 / 3

-- 圆形使用的迷雾 shader 文件
local MIST_SHADER_PATH = Mod.info.path .. "/assets/shaders/gb_mist.frag"

local GBCircle, circle_super = Class(Object)

function GBCircle:init(x, y, radius)
    circle_super.init(self, x, y, radius * 2, radius * 2)

    self.radius = radius
    self.alpha = 0
    self.white_amount = 0
    self.time = 0
    self.shader = love.graphics.newShader(MIST_SHADER_PATH)
end

function GBCircle:update()
    circle_super.update(self)
    self.time = self.time + DT
end

function GBCircle:draw()
    local old_shader = love.graphics.getShader()
    local old_r, old_g, old_b, old_a = love.graphics.getColor()

    self.shader:send("time", self.time)
    self.shader:send("white_amount", self.white_amount)

    love.graphics.setShader(self.shader)
    love.graphics.setColor(1, 1, 1, self.alpha)
    love.graphics.circle("fill", 0, 0, self.radius, CIRCLE_SEGMENTS)
    love.graphics.setColor(old_r, old_g, old_b, old_a)
    love.graphics.setShader(old_shader)
end

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
    self.circle = nil
end

function GB:spawnCircle()
    local center_x, center_y = self.dog:getRelativePos(self.dog.width / 2, self.dog.height / 2)
    local circle = GBCircle(center_x, center_y, CIRCLE_INITIAL_RADIUS)
    circle.layer = self.dog.layer - 1
    self.circle = self:spawnObject(circle)

    self.timer:tween(
        CIRCLE_INTRO_TIME,
        circle,
        {radius = CIRCLE_START_RADIUS, alpha = 1},
        "out-cubic",
        function()
            self.timer:tween(
                CIRCLE_TIME - CIRCLE_INTRO_TIME,
                circle,
                {radius = CIRCLE_MIN_RADIUS, white_amount = 1},
                "linear",
                function()
                    if circle.parent then
                        circle:remove()
                    end
                    if self.circle == circle then
                        self.circle = nil
                    end
                end
            )
        end
    )
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

    self:spawnCircle()
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
