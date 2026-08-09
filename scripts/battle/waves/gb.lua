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
-- GB 光束每次命中的伤害
local BLAST_DAMAGE = 66
-- GB 光束重复伤害的间隔
local BLAST_INVULN_TIME = 6 / FPS
-- GB 目标权重：Kris 和 Ralsei 比 Susie 更容易被选中
local TARGET_WEIGHTS = {
    {id = "kris", weight = 2},
    {id = "ralsei", weight = 2},
    {id = "susie", weight = 1},
}

-- Dog 白色覆盖的褪去时长
local WHITE_FADE_TIME = 0.5
-- Dog eye 动画使用的帧间隔
local EYE_FRAME_TIME = 3 / FPS
-- Dog eye 动画的资源路径
local EYE_SPRITE = "enemies/dog/eye/"
-- 旋转完成后 Dog 复制体的持续时长
local DOG_FLASH_TIME = 0.5
-- 旋转完成后 Dog 复制体的初始缩放
local DOG_FLASH_START_SCALE = 2
-- 旋转完成后 Dog 复制体的最大缩放
local DOG_FLASH_SCALE = 4

-- 中央矩形出现到旋转完成的时长
local CENTER_RECTANGLE_TIME = 0.5
-- 中央矩形的宽度
local CENTER_RECTANGLE_WIDTH = 5
-- 中央矩形结束时的缩放
local CENTER_RECTANGLE_END_SCALE = 0

-- 回合结束前的额外缓冲时长
local WAVE_BUFFER = 1 / 3

local GBCircle, circle_super = Class(Ellipse)

function GBCircle:init(x, y, radius)
    circle_super.init(self, x, y, radius, radius)

    self.radius = radius
    self.alpha = 0
    self.white_amount = 0
    self.time = 0
    -- 迷雾 shader：vars 支持函数值，每帧求值送进 shader
    self:addFX(ShaderFX("gb_mist", {
        time = function() return self.time end,
        white_amount = function() return self.white_amount end,
    }))
end

function GBCircle:update()
    circle_super.update(self)
    -- radius 被外面 tween 驱动，同步成椭圆的实际大小
    self:setSize(self.radius * 2, self.radius * 2)
    self.time = self.time + DT
end

local GBParticle, particle_super = Class(Ellipse)

function GBParticle:init(x, y, target_x, target_y, radius, travel_time)
    particle_super.init(self, x, y, radius, radius)

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

local function pickGBTarget()
    local candidates = {}
    local total_weight = 0

    for _, entry in ipairs(TARGET_WEIGHTS) do
        local battler = Game.battle:getPartyBattler(entry.id)
        if battler and battler:canTarget() then
            total_weight = total_weight + entry.weight
            table.insert(candidates, {
                battler = battler,
                weight = entry.weight,
            })
        end
    end

    if total_weight == 0 then
        return Game.battle:randomTarget()
    end

    local roll = love.math.random() * total_weight
    for _, candidate in ipairs(candidates) do
        roll = roll - candidate.weight
        if roll < 0 then
            return candidate.battler
        end
    end

    return candidates[#candidates].battler
end

function GB:init()
    super.init(self)

    self.time = getWaveTime()
    self.dog = nil
    self.white_fx = nil
    self.circle = nil
    self.particle_spawn_timer = nil
    self.dog_flash = nil
    self.eye = nil
    self.center_rectangle = nil
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

function GB:spawnDogFlash()
    local source_sprite = self.dog:getActiveSprite()
    if not source_sprite or not source_sprite.texture then
        return
    end

    local center_x, center_y = self.dog:getRelativePos(
        self.dog.width / 2,
        self.dog.height / 2,
        Game.battle
    )
    local dog_flash = Sprite(
        source_sprite.texture,
        center_x,
        center_y,
        source_sprite.width,
        source_sprite.height
    )
    dog_flash:setOrigin(0.5, 0.5)
    dog_flash:setScale(DOG_FLASH_START_SCALE)
    dog_flash.layer = self.dog.layer + 1
    self.dog_flash = self:spawnObject(dog_flash)

    self.timer:tween(
        DOG_FLASH_TIME,
        dog_flash,
        {scale_x = DOG_FLASH_SCALE, scale_y = DOG_FLASH_SCALE, alpha = 0},
        "linear",
        function()
            if dog_flash.parent then
                dog_flash:remove()
            end
            if self.dog_flash == dog_flash then
                self.dog_flash = nil
            end
        end
    )
end

function GB:spawnEye()
    if not self.dog then
        return
    end

    if self.eye then
        self.eye:remove()
        self.eye = nil
    end

    local source_sprite = self.dog:getActiveSprite()
    local eye = Sprite(EYE_SPRITE, source_sprite and source_sprite.x or 0, source_sprite and source_sprite.y or 0)
    eye.layer = (source_sprite and source_sprite.layer or 0) + 1
    self.eye = self.dog:addChild(eye)

    eye:setAnimation({
        EYE_SPRITE,
        EYE_FRAME_TIME,
        false,
        frames = {"1-6"},
        callback = function(sprite)
            if self.eye == sprite and sprite.parent then
                sprite:setAnimation({
                    EYE_SPRITE,
                    EYE_FRAME_TIME,
                    true,
                    frames = {1, 6},
                })
            end
        end,
    })
end

function GB:spawnCenterRectangle()
    local center_x = self.dog:getRelativePos(self.dog.width / 2, 0, Game.battle)
    local rectangle = Rectangle(center_x, SCREEN_HEIGHT / 2, CENTER_RECTANGLE_WIDTH, SCREEN_HEIGHT)
    rectangle:setOrigin(0.5, 0.5)
    rectangle.layer = self.dog.layer + 0.5
    self.center_rectangle = self:spawnObject(rectangle)

    self.timer:tween(
        CENTER_RECTANGLE_TIME,
        rectangle,
        {scale_x = CENTER_RECTANGLE_END_SCALE, scale_y = CENTER_RECTANGLE_END_SCALE},
        "out-cubic",
        function()
            if rectangle.parent then
                rectangle:remove()
            end
            if self.center_rectangle == rectangle then
                self.center_rectangle = nil
            end
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
    bullet.damage = BLAST_DAMAGE
    bullet.inv_timer = BLAST_INVULN_TIME

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
    Assets.playSound("snd_knight_stretch", 1, 0.75)

    local attackers = self:getAttackers()
    self.dog = attackers[1]

    self.party_health = {}
    for _, battler in ipairs(Game.battle.party) do
        self.party_health[battler.chara.id] = battler.chara:getHealth()
    end

    if not self.dog then
        self:spawnBlaster()
        return
    end

    self.dog.current_target = pickGBTarget()

    self:spawnCircle()
    self.white_fx = self.dog:addFX(ColorMaskFX({1, 1, 1}, 0), "gb_white")
    self.timer:tween(SPIN_TIME * (SPIN_LOOPS - 1) / SPIN_LOOPS, self.white_fx, {amount = 1}, "linear")
    self:spawnParticle()
    self.particle_spawn_timer = self:getParticleSpawnInterval()
    self.timer:after(SPIN_TIME - CENTER_RECTANGLE_TIME, function()
        if self.dog then
            self:spawnCenterRectangle()
        end
    end)

    playSpin(self.dog, SPIN_LOOPS, function()
        Assets.playSound("snd_dogresidue")
        self:spawnEye()
        self:spawnDogFlash()
        self:spawnBlaster()
    end)
end

function GB:onEnd()
    if self.dog then
        self.dog.gb_party_health = self.party_health
    end

    if self.white_fx and self.dog then
        self.dog:removeFX(self.white_fx)
        self.white_fx = nil
    end

    if self.dog then
        self.dog:setAnimation("idle")
    end

    if self.dog_flash then
        self.dog_flash:remove()
        self.dog_flash = nil
    end
    if self.eye then
        self.eye:remove()
        self.eye = nil
    end
    if self.center_rectangle then
        self.center_rectangle:remove()
        self.center_rectangle = nil
    end
end

return GB
