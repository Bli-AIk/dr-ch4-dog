---@class Bone : Wave
local Bone, super = Class(Wave)

-- 骨头从战斗框右侧移动到左侧所需的时间（秒）
local TRAVEL_TIME = 2.0

-- 两对骨头生成之间的间隔时间（秒）
local SPAWN_INTERVAL = 0.5

-- 上下骨头之间的间距相对于灵魂高度的倍数
local SOUL_GAP_FACTOR = 1.25

-- 空隙最大偏移量
local MAX_GAP_OFFSET = 30

-- 自定义 in-out-back 曲线的回弹幅度。
local BACK_OVERSHOOT = 3.5

-- Timer:tween accepts a progress function. This keeps the normal in-out-back shape,
-- but increases its overshoot beyond Kristal's default bounciness.
local function exaggeratedInOutBack(t)
    local s = BACK_OVERSHOOT * 1.525
    t = t * 2

    if t < 1 then
        return 0.5 * (t * t * ((s + 1) * t - s))
    end

    t = t - 2
    return 0.5 * (t * t * ((s + 1) * t + s) + 2)
end

-- Keep the bone below the arena until it crosses 0, then put it above the
-- arena for the visible travel. Crossing 1 means it has overshot the target,
-- so put it below the arena again.
local function layerAwareEasing(bullet)
    local previous_value = 0

    return function(t)
        local value = exaggeratedInOutBack(t)

        if previous_value < 0 and value >= 0 then
            bullet:setLayer(BATTLE_LAYERS["above_arena"])
        elseif previous_value < 1 and value >= 1 then
            bullet:setLayer(BATTLE_LAYERS["below_arena"])
        end

        previous_value = value
        return value
    end
end

function Bone:onStart()
    local arena = Game.battle.arena
    local soul = Game.battle.soul

    local arena_left = arena:getLeft()
    local arena_right = arena:getRight()
    local arena_top = arena:getTop()
    local arena_bottom = arena:getBottom()

    local gap = soul.height * SOUL_GAP_FACTOR

    local function spawnPair()
        local bone_type = MathUtils.randomInt(1, 3) == 1 and "sans_bone" or "pap_bone"
        local gap_offset = MathUtils.randomInt(-MAX_GAP_OFFSET, MAX_GAP_OFFSET + 1)
        local gap_center = (arena_top + arena_bottom) / 2 + gap_offset
        local top_length = gap_center - gap / 2 - arena_top
        local bottom_length = arena_bottom - (gap_center + gap / 2)
        local top_bone = self:spawnBullet(bone_type, arena_right, arena_top, top_length, "top")
        local bottom_bone = self:spawnBullet(bone_type, arena_right, arena_bottom, bottom_length, "bottom")

        -- Keep the pair fully inside the arena horizontally.
        local start_x = arena_right - top_bone.width / 2
        local target_x = arena_left + top_bone.width / 2
        top_bone:setPosition(start_x, arena_top)
        bottom_bone:setPosition(start_x, arena_bottom)
        top_bone:setLayer(BATTLE_LAYERS["below_arena"])
        bottom_bone:setLayer(BATTLE_LAYERS["below_arena"])

        self.timer:tween(TRAVEL_TIME, top_bone, { x = target_x }, layerAwareEasing(top_bone))
        self.timer:tween(TRAVEL_TIME, bottom_bone, { x = target_x }, layerAwareEasing(bottom_bone))
    end

    self.timer:everyInstant(SPAWN_INTERVAL, spawnPair)
end

return Bone
