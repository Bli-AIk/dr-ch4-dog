---@class GasterBlaster : Bullet
---@overload fun(x: number, y: number, target_x: number, target_y: number, initial_rotation?: number, target_rotation?: number, wait_time?: number, firing_time?: number, tp?: number): GasterBlaster
local GasterBlaster, super = Class(Bullet)

local SPRITE_PATH = "bullets/gb/spr_gasterblaster_"
local BEAM_TEXTURE = "bullets/gb/beam"
local BEAM_LENGTH = 600
local BEAM_WIDTH = 24
local WARNING_FRAMES = 12
local WARNING_FRAME_TIME = 3
local FIRE_OPEN_FRAME_TIME = 2
local FADE_FRAMES = 15
local BEAM_SCALE_OFFSET = 0.25
local BEAM_SCALE_AMPLITUDE = 0.2
local BEAM_SCALE_PERIOD = 4
local BEAM_SCALE_FADE_DIVISOR = 8

local function setBlasterFrame(blaster, frame)
    if blaster.blaster_frame == frame then return end

    blaster.sprite:setSprite(SPRITE_PATH .. frame)
    blaster.sprite:setOrigin(0.5, 0.5)
    blaster.blaster_frame = frame
end

function GasterBlaster:setBeamScale(scale)
    self.beam_scale = math.max(0, scale)
    self.beam:setScale(1, self.beam_scale)

    -- Keep the damage and graze area as wide as the animated beam.
    local beam_width = BEAM_WIDTH * self.beam_scale
    self.collider.x = -beam_width / 2
    self.collider.width = beam_width
end

function GasterBlaster:updateBeamPulse()
    local blaster_scale = self:getScale()
    local pulse_time = self.firing_time - self.fire_time
    local beam_scale = blaster_scale + BEAM_SCALE_OFFSET
        + math.sin(pulse_time / BEAM_SCALE_PERIOD) * BEAM_SCALE_AMPLITUDE
    self:setBeamScale(beam_scale)
end

---@param x number # The starting X position.
---@param y number # The starting Y position.
---@param target_x number # The X position approached before firing.
---@param target_y number # The Y position approached before firing.
---@param initial_rotation? number # Rotation in radians. Zero points the blaster down.
---@param target_rotation? number # Rotation in radians reached before firing.
---@param wait_time? number # Warning duration in frames at 30 FPS.
---@param firing_time? number # Beam duration in frames at 30 FPS.
---@param tp? number # TP gained on the first graze and each following frame.
function GasterBlaster:init(x, y, target_x, target_y, initial_rotation, target_rotation, wait_time, firing_time, tp)
    super.init(self, x, y, SPRITE_PATH .. "0")

    self:setOrigin(0.5, 0.5)
    self.layer = BATTLE_LAYERS["above_arena"]

    self.target_x = target_x
    self.target_y = target_y
    self.initial_rotation = initial_rotation or 0
    self.target_rotation = target_rotation
        or (MathUtils.angle(x, y, target_x, target_y) - math.pi / 2)
    self.wait_time = wait_time or 40
    self.firing_time = firing_time or 40
    self.fade_time = FADE_FRAMES

    self.time = 0
    self.fire_time = 0
    self.fade_time_elapsed = 0
    self.phase = "approach"
    self.rotation = self.initial_rotation

    -- Match SansBone's one-hit-per-frame damage behavior.
    self.inv_timer = 1 / 30
    self.destroy_on_hit = false
    self.damage = 1

    -- Bullet graze logic gives this value again every frame after the first graze.
    self.tp = tp or 1.6

    -- The beam is a child for rendering, while this bullet owns its collider.
    self.beam = Sprite(BEAM_TEXTURE)
    self.beam:setOrigin(1, 0.5)
    self.beam:setPosition(0, self.height / 2)
    self.beam.rotation = -math.pi / 2
    self.beam.layer = -1
    self.beam.inherit_color = true
    self.beam.visible = false
    self:addChild(self.beam)

    -- The texture points left; this local hitbox points down at rotation zero.
    self:setHitbox(-BEAM_WIDTH / 2, self.height / 2, BEAM_WIDTH, BEAM_LENGTH)
    self:setBeamScale(1)
    self.collidable = false
    self.remove_offscreen = false

    self.sprite:setOrigin(0.5, 0.5)
    self.blaster_frame = 0
end

function GasterBlaster:fire()
    self.phase = "fire"
    self.fire_time = 0
    self.collidable = true
    self.beam.visible = true
    self:updateBeamPulse()
    setBlasterFrame(self, 5)
    Assets.playSound("gb/snd_fire")
end

function GasterBlaster:startFade()
    self.phase = "fade"
    self.fade_time_elapsed = 0
    self.collidable = false
end

function GasterBlaster:update()
    local frame_step = DTMULT
    self.time = self.time + frame_step

    if self.phase == "approach" then
        self.x = self.x + ((self.target_x - self.x) / 8) * frame_step
        self.y = self.y + ((self.target_y - self.y) / 8) * frame_step
        self.rotation = self.rotation
            + (MathUtils.angleDiff(self.target_rotation, self.rotation) / 8) * frame_step

        local warning_start = self.wait_time - WARNING_FRAMES
        if self.time >= warning_start then
            local warning_frame = math.min(
                4,
                math.floor(math.max(0, self.time - warning_start) / WARNING_FRAME_TIME) + 1
            )
            setBlasterFrame(self, warning_frame)
        end

        if self.time >= self.wait_time then
            self:fire()
        end
    elseif self.phase == "fire" then
        self.fire_time = self.fire_time + frame_step
        self:updateBeamPulse()

        -- Move away from the arena along the opposite direction of the beam.
        self.x = self.x + math.sin(self.rotation) * self.fire_time * frame_step
        self.y = self.y - math.cos(self.rotation) * self.fire_time * frame_step

        if self.fire_time >= FIRE_OPEN_FRAME_TIME then
            setBlasterFrame(self, 4)
        end
        if self.fire_time >= self.firing_time then
            self:startFade()
        end
    elseif self.phase == "fade" then
        self.fade_time_elapsed = self.fade_time_elapsed + frame_step
        self.alpha = math.max(0, 1 - self.fade_time_elapsed / self.fade_time)
        self:setBeamScale(self.beam_scale * (1 - frame_step / BEAM_SCALE_FADE_DIVISOR))
        if self.fade_time_elapsed >= self.fade_time then
            self:remove()
            return
        end
    end

    super.update(self)
end

function GasterBlaster:onWaveSpawn(wave)
    Assets.playSound("gb/snd_intro")
end

return GasterBlaster
