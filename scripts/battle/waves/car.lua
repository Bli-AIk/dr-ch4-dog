---@class Car : Wave
local Car, super = Class(Wave)

local FPS = 30
local FLIP_HALF_TIME = 4 / FPS
local FLIP_BACK_TIME = 8 / FPS
local INTRO_TIME = 12 / FPS
local INTRO_DISTANCE = 30
local CHARGE_TIME = 5 / FPS
local RETREAT_TIME = 3 / FPS
local RETREAT_DISTANCE = 30
local BOOM_TIME = 2 / FPS
local HIT_COUNT = 30
local EFFECT_LAYER = BATTLE_LAYERS["top"]
local IMPACT_SHAKE = 4
local SPIN_FRAME_COUNT = 27
local SPIN_TIME = SPIN_FRAME_COUNT / FPS
local PARABOLA_HEIGHT = 48
local SQUASHED_SCALE_Y = 1.8

function Car:init()
    super.init(self)

    self.time = 10
    self.dog = nil
    self.original_x = nil
    self.original_y = nil
    self.original_scale_x = nil
    self.original_scale_y = nil
    self.hit_count = 0
end

function Car:getCarFrontOffset()
    local sprite = self.dog:getActiveSprite()
    local offset_x = sprite:getOffset()[1]
    local origin_x = self.dog:getOriginExact()

    return (origin_x - offset_x) * math.abs(self.dog.scale_x)
end

function Car:getCrashEdge()
    return Game.battle.arena and Game.battle.arena:getRight() or 0
end

function Car:spawnCarBoom(edge_x)
    local _, boom_y = self.dog:getRelativePos(
        self.dog.width / 2,
        self.dog.height / 2,
        Game.battle
    )
    local boom = self:spawnSprite(
        "enemies/dog/car_boom",
        edge_x,
        boom_y,
        EFFECT_LAYER
    )

    self.timer:after(BOOM_TIME, function()
        if boom.parent then
            boom:remove()
        end
    end)
end

function Car:restoreDog()
    if not self.dog then
        return
    end

    self.dog:setPosition(self.original_x, self.original_y)
    self.dog.scale_x = self.original_scale_x or 2
    self.dog.scale_y = self.original_scale_y or 2
    self.dog:setAnimation("idle")
end

function Car:finishHits(crash_edge)
    if not self.dog then
        return
    end

    local explosion = self.dog:explode(0, 0, true)
    if explosion then
        explosion.layer = EFFECT_LAYER
    end
    self.dog:setAnimation("spin")

    local elapsed = 0
    local start_x, start_y = self.dog:getPosition()
    self.timer:during(SPIN_TIME, function()
        elapsed = elapsed + DT
        local progress = math.min(elapsed / SPIN_TIME, 1)
        local eased = Utils.ease(0, 1, progress, "in-out-cubic")

        self.dog.x = MathUtils.lerp(start_x, self.original_x, eased)
        self.dog.y = self.original_y - (PARABOLA_HEIGHT * 4 * progress * (1 - progress))
    end, function()
        self:restoreDog()
    end)
end

function Car:hitArena(crash_edge, crash_x)
    if not self.dog or not self.dog.parent then
        return
    end

    self.hit_count = self.hit_count + 1
    local shake_x = love.math.random(0, 1) == 0 and -IMPACT_SHAKE or IMPACT_SHAKE
    local shake_y = love.math.random(0, 1) == 0 and -IMPACT_SHAKE or IMPACT_SHAKE
    Game.battle:shakeCamera(shake_x, shake_y)
    self:spawnCarBoom(crash_edge)

    if self.hit_count >= HIT_COUNT then
        self:finishHits(crash_edge)
        return
    end

    self.timer:tween(
        RETREAT_TIME,
        self.dog,
        { x = crash_x + RETREAT_DISTANCE },
        "out-cubic",
        function()
            self.timer:tween(
                CHARGE_TIME,
                self.dog,
                { x = crash_x, scale_y = self.original_scale_y },
                "out-cubic",
                function()
                    self:hitArena(crash_edge, crash_x)
                end
            )
        end
    )
end

function Car:beginDrive()
    if not self.dog then
        return
    end

    self.dog:setScaleOrigin(0.5, 1)

    local crash_edge = self:getCrashEdge()
    local front_offset = self:getCarFrontOffset()
    local crash_x = crash_edge + front_offset
    local intro_x = math.max(self.dog.x + INTRO_DISTANCE, crash_x + RETREAT_DISTANCE)

    self.timer:tween(
        INTRO_TIME,
        self.dog,
        { x = intro_x, scale_y = SQUASHED_SCALE_Y },
        "out-cubic",
        function()
            self.timer:tween(
                CHARGE_TIME,
                self.dog,
                { x = crash_x, scale_y = self.original_scale_y },
                "out-cubic",
                function()
                    self:hitArena(crash_edge, crash_x)
                end
            )
        end
    )
end

function Car:onStart()
    self.dog = self:getAttackers()[1]
    if not self.dog then
        return
    end

    self.original_x, self.original_y = self.dog:getPosition()
    self.original_scale_x = self.dog.scale_x
    self.original_scale_y = self.dog.scale_y
    self.dog.scale_x = 2
    self.dog:setAnimation({
        "speak/",
        1 / FPS,
        true,
        frames = {1},
    })

    self.timer:tween(
        FLIP_HALF_TIME,
        self.dog,
        {scale_x = 0},
        "in-out-cubic",
        function()
            self.dog:setAnimation("car")
            self.timer:tween(
                FLIP_HALF_TIME,
                self.dog,
                {scale_x = -2},
                "in-out-cubic",
                function()
                    self.timer:tween(
                        FLIP_BACK_TIME,
                        self.dog,
                        {scale_x = 2},
                        "in-out-cubic",
                        function()
                            self:beginDrive()
                        end
                    )
                end
            )
        end
    )
end

function Car:onEnd()
    if not self.dog then
        return
    end

    self:restoreDog()
end

return Car
