---@class Car : Wave
-- Car 回合类及其 Wave 父类
local Car, super = Class(Wave)

-- 游戏使用的帧率
local FPS = 30
-- Dog 翻转到横向缩放 0 的时长
local FLIP_HALF_TIME = 4 / FPS
-- Dog 从反向缩放恢复到正向缩放的时长
local FLIP_BACK_TIME = 8 / FPS
-- 翻转完成后第一次向右后撤的时长
local INTRO_TIME = 12 / FPS
-- 第一次后撤的最小距离
local INTRO_DISTANCE = 30
-- Dog 向左冲撞的时长
local CHARGE_TIME = 3 / FPS
-- 每次撞击后向右后撤的时长
local RETREAT_TIME = 3 / FPS
-- 每次后撤的距离
local RETREAT_DISTANCE = 30
-- car_boom 贴图的持续时长
local BOOM_TIME = 2 / FPS
-- Dog 撞击战斗框的总次数
local HIT_COUNT = 30
-- car_boom 和 explode 使用的最上方图层
local EFFECT_LAYER = BATTLE_LAYERS["top"]
-- 每次撞击时的镜头震动幅度
local IMPACT_SHAKE = 4
-- Dog spin 动画的帧间隔
local SPIN_FRAME_TIME = 1 / FPS
-- Dog 飞回原位的总时长
local RETURN_TIME = 30 / FPS
-- Dog 沿抛物线飞回时的最高高度
local PARABOLA_HEIGHT = 72 * 2
-- Dog 后撤蓄力时的纵向缩放
local SQUASHED_SCALE_Y = 1.8
-- 每个 bone 贴图弹幕的资源路径
local BONE_SPRITE = "bullets/bone"
-- bone 从 boom 连续飞到窗口外的总时长
local BONE_FLIGHT_TIME = 54 / FPS * 1.5
-- bone 经过 arena 底部时的抛物线进度
local BONE_TARGET_PROGRESS = 0.65
-- bone 顶点所在的抛物线进度
local BONE_VERTEX_PROGRESS = 0.28
-- bone 逆时针旋转的速度
local BONE_ROTATION_SPEED = math.rad(360)
-- bone 目标点距离 arena 右边缘的间距
local BONE_TARGET_MARGIN = 12
-- bone 最左目标点距离 arena 左边缘的间距
local BONE_TARGET_LEFT_MARGIN = -48
-- bone 目标点的常规随机偏移范围
local BONE_TARGET_JITTER = 40
-- bone 目标点发生随机突变的概率
local BONE_TARGET_MUTATION_CHANCE = 0.35
-- bone 目标点从左到右循环的次数
local BONE_TARGET_CYCLE_COUNT = 3
-- 每个左到右循环包含的撞击次数
local BONE_TARGETS_PER_CYCLE = HIT_COUNT / BONE_TARGET_CYCLE_COUNT

function Car:init()
    super.init(self)

    self.time = 9
    self.dog = nil
    self.original_x = nil
    self.original_y = nil
    self.original_scale_x = nil
    self.original_scale_y = nil
    self.hit_count = 0
    self.bone_target_index = 0
end

function Car:getCarFrontOffset()
    -- 当前 car 动画的 sprite
    local sprite = self.dog:getActiveSprite()
    -- car sprite 相对于 Dog 锚点的水平偏移
    local offset_x = sprite:getOffset()[1]
    -- Dog 锚点相对于自身尺寸的水平位置
    local origin_x = self.dog:getOriginExact()

    return (origin_x - offset_x) * math.abs(self.dog.scale_x)
end

function Car:getCrashEdge()
    return Game.battle.arena and Game.battle.arena:getRight() or 0
end

function Car:getBoneTargetX(arena)
    self.bone_target_index = self.bone_target_index + 1

    -- 目标点默认从 arena 左侧逐步滚动到右侧
    -- 目标点允许出现的最小 x 坐标
    local left = arena:getLeft() + BONE_TARGET_LEFT_MARGIN
    -- 目标点允许出现的最大 x 坐标
    local right = arena:getRight() - BONE_TARGET_MARGIN
    -- 当前目标点所在循环中的序号
    local cycle_index = (self.bone_target_index - 1) % BONE_TARGETS_PER_CYCLE
    -- 当前目标点在本次左到右循环中的进度
    local order_progress = cycle_index / math.max(BONE_TARGETS_PER_CYCLE - 1, 1)
    -- 未发生突变时的有序目标位置
    local target_x = MathUtils.lerp(left, right, order_progress)

    if love.math.random() < BONE_TARGET_MUTATION_CHANCE then
        -- 少量骨头直接跳到一个随机位置
        target_x = left + love.math.random() * (right - left)
    else
        -- 大多数骨头只在有序位置附近产生小幅偏移
        target_x = target_x + love.math.random(-BONE_TARGET_JITTER, BONE_TARGET_JITTER)
    end

    return MathUtils.clamp(target_x, left, right)
end

function Car:spawnBone(start_x, start_y)
    local arena = Game.battle.arena
    if not arena then
        return
    end

    -- 本次骨头在 arena 底部的目标 x 坐标
    local target_x = self:getBoneTargetX(arena)
    -- 本次骨头在 arena 底部的目标 y 坐标
    local target_y = arena:getBottom()
    -- 抛物线经过目标点时的进度
    local target_progress = BONE_TARGET_PROGRESS
    -- 抛物线顶点所在的进度
    local vertex_progress = BONE_VERTEX_PROGRESS
    -- 让 x 在目标进度时恰好经过目标点，并在之后继续向窗口外移动
    local exit_x = start_x + ((target_x - start_x) / target_progress)
    -- 起点到 arena 底部目标点的垂直位移
    local vertical_delta = target_y - start_y
    -- 抛物线的二次项系数
    local parabola_coefficient = vertical_delta
        / (target_progress * target_progress - 2 * target_progress * vertex_progress)
    -- 抛物线顶点的 y 坐标
    local vertex_y = start_y - (parabola_coefficient * vertex_progress * vertex_progress)
    -- 本次生成的 bone 贴图弹幕
    local bone = self:spawnBullet(BONE_SPRITE, start_x, start_y)
    bone.damage = 66

    -- 骨头沿同一条抛物线飞行时已经经过的时间
    local elapsed = 0
    self.timer:during(BONE_FLIGHT_TIME, function()
        if not bone.parent then
            return false
        end

        elapsed = elapsed + DT
        -- 轨迹的时间进度
        local progress = math.min(elapsed / BONE_FLIGHT_TIME, 1)
        -- 只控制沿抛物线运动的速度，不改变抛物线形状
        local path_progress = Utils.ease(0, 1, progress, "out-cubic")
        -- 当前点相对于抛物线顶点的进度
        local vertex_offset = path_progress - vertex_progress

        bone.x = MathUtils.lerp(start_x, exit_x, path_progress)
        bone.y = vertex_y + (parabola_coefficient * vertex_offset * vertex_offset)
        bone.rotation = bone.rotation - (BONE_ROTATION_SPEED * DT)
    end, function()
        if bone.parent then
            bone:remove()
        end
    end)
end

function Car:spawnCarBoom(edge_x)
    -- car_boom 贴图在战斗坐标中的垂直位置
    local _, boom_y = self.dog:getRelativePos(
        self.dog.width / 2,
        self.dog.height / 2,
        Game.battle
    )
    -- 本次撞击生成的爆炸贴图
    local boom = self:spawnSprite(
        "enemies/dog/car_boom",
        edge_x,
        boom_y,
        EFFECT_LAYER
    )
    self:spawnBone(edge_x, boom_y)

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

    -- 框架自带的爆炸效果
    local explosion = self.dog:explode(0, 0, true)
    if explosion then
        explosion.layer = EFFECT_LAYER
    end
    self.dog:setAnimation({
        "spin/spin",
        SPIN_FRAME_TIME,
        true,
    })

    -- Dog 飞回原位时已经经过的时间
    local elapsed = 0
    -- 抛物线运动的起点
    local start_x, start_y = self.dog:getPosition()
    self.timer:during(RETURN_TIME, function()
        elapsed = elapsed + DT
        -- 当前飞行动画的归一化进度
        local progress = math.min(elapsed / RETURN_TIME, 1)
        -- 水平移动使用的平滑进度
        local eased = Utils.ease(0, 1, progress, "out-cubic")

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
    -- 每次撞击随机决定镜头震动的横向方向
    local shake_x = love.math.random(0, 1) == 0 and -IMPACT_SHAKE or IMPACT_SHAKE
    -- 每次撞击随机决定镜头震动的纵向方向
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

    -- 战斗框右侧边缘
    local crash_edge = self:getCrashEdge()
    -- car 左前端到 Dog 锚点的距离
    local front_offset = self:getCarFrontOffset()
    -- Dog 冲撞时的目标位置
    local crash_x = crash_edge + front_offset
    -- 第一次冲撞前的后撤位置
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
