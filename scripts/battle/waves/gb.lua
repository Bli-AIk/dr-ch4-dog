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

-- 白色粒子的最短生成间隔
local PARTICLE_MIN_SPAWN_INTERVAL = 1 / FPS / 10
-- 白色粒子的最长生成间隔
local PARTICLE_MAX_SPAWN_INTERVAL = 5 / FPS
-- 白色粒子的最小半径
local PARTICLE_MIN_RADIUS = 1.5
-- 白色粒子的最大半径
local PARTICLE_MAX_RADIUS = 4
-- 白色粒子飞向中心的最短时间
local PARTICLE_MIN_TRAVEL_TIME = 12 / FPS
-- 白色粒子飞向中心的最长时间
local PARTICLE_MAX_TRAVEL_TIME = 20 / FPS

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

local GBParticle, particle_super = Class(Object)

function GBParticle:init(x, y, target_x, target_y, radius, travel_time)
    particle_super.init(self, x, y, radius * 2, radius * 2)

    self.start_x = x
    self.start_y = y
    self.target_x = target_x
    self.target_y = target_y
    self.radius = radius
    self.travel_time = travel_time
    self.progress = 0
    self.layer = 1
end

function GBParticle:update()
    particle_super.update(self)

    self.progress = self.progress + DT / self.travel_time
    local progress = math.min(self.progress, 1)
    local eased_progress = 1 - (1 - progress) ^ 3

    self.x = self.start_x + (self.target_x - self.start_x) * eased_progress
    self.y = self.start_y + (self.target_y - self.start_y) * eased_progress

    if self.progress >= 1 then
        self:remove()
    end
end

function GBParticle:draw()
    local old_r, old_g, old_b, old_a = love.graphics.getColor()

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", 0, 0, self.radius, CIRCLE_SEGMENTS)
    love.graphics.setColor(old_r, old_g, old_b, old_a)
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
    self.particle_spawn_timer = nil
end

function GB:getParticleSpawnInterval()
    -- 让较长的生成间隔更常出现
    local bias = math.sqrt(love.math.random())
    return PARTICLE_MIN_SPAWN_INTERVAL
        + bias * (PARTICLE_MAX_SPAWN_INTERVAL - PARTICLE_MIN_SPAWN_INTERVAL)
end

function GB:update()
    super.update(self)

    if not self.particle_spawn_timer then
        return
    end

    if not self.circle or not self.white_fx or self.white_fx.amount >= 1 then
        self.particle_spawn_timer = nil
        return
    end

    self.particle_spawn_timer = self.particle_spawn_timer - DT
    while self.particle_spawn_timer <= 0 do
        self:spawnParticle()
        self.particle_spawn_timer = self.particle_spawn_timer + self:getParticleSpawnInterval()
    end
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

function GB:spawnParticle()
    if not self.circle or self.circle.radius <= 0 then
        return
    end

    local angle = love.math.random() * math.pi * 2
    local radius = PARTICLE_MIN_RADIUS
        + love.math.random() * (PARTICLE_MAX_RADIUS - PARTICLE_MIN_RADIUS)
    local spawn_radius = math.max(self.circle.radius - radius * 0.25, 0)
    local center_x, center_y = self.circle.x, self.circle.y
    local x = center_x + math.cos(angle) * spawn_radius
    local y = center_y + math.sin(angle) * spawn_radius
    local travel_time = PARTICLE_MIN_TRAVEL_TIME
        + love.math.random() * (PARTICLE_MAX_TRAVEL_TIME - PARTICLE_MIN_TRAVEL_TIME)

    local particle = GBParticle(x, y, center_x, center_y, radius, travel_time)
    particle.layer = self.circle.layer + 0.1
    self:spawnObject(particle)
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
    self:spawnParticle()
    self.particle_spawn_timer = self:getParticleSpawnInterval()

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
