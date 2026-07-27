---@alias BoneAnchor "top"|"center"|"bottom"

---@class BoneBullet : Bullet
---@overload fun(x: number, y: number, length?: number, anchor?: BoneAnchor): BoneBullet
local BoneBullet, super = Class(Bullet)

local ANCHOR_ORIGINS = {
    top = 0,
    center = 0.5,
    bottom = 1,
}

---@param x number # The X position of the bullet.
---@param y number # The Y position of the bullet.
---@param length? number # The full length of the bone in pixels.
---@param anchor? BoneAnchor # Which point of the bone is placed at x/y.
---@param top_texture string # The top cap texture.
---@param bottom_texture string # The bottom cap texture.
---@param fill_x number # The left edge of the opaque join, in texture pixels.
---@param fill_width number # The width of the opaque join, in texture pixels.
function BoneBullet:init(x, y, length, anchor, top_texture, bottom_texture, fill_x, fill_width)
    super.init(self, x, y)
    self:setScale(1)

    local top_sprite = Sprite(top_texture)
    local bottom_sprite = Sprite(bottom_texture)
    local min_length = top_sprite.height + bottom_sprite.height

    self.length = math.max(length or min_length + 4, min_length)
    self.width = math.max(top_sprite.width, bottom_sprite.width)
    self:setSize(self.width, self.length)
    self:setAnchor(anchor or "center")

    local fill_height = self.length - min_length

    -- The rectangle and hitbox use the same opaque width, excluding transparent cap pixels.
    local fill = Rectangle(fill_x, top_sprite.height, fill_width, fill_height)
    fill.layer = -1
    fill.inherit_color = true
    self:addChild(fill)

    top_sprite:setPosition(0, 0)
    top_sprite.inherit_color = true
    self:addChild(top_sprite)
    self.top_sprite = top_sprite

    bottom_sprite:setPosition(0, self.length - bottom_sprite.height)
    bottom_sprite.inherit_color = true
    self:addChild(bottom_sprite)
    self.bottom_sprite = bottom_sprite

    -- Only the filled middle section can damage the soul.
    self:setHitbox(fill_x, top_sprite.height, fill_width, fill_height)

end

---@param anchor BoneAnchor # Which point of the bone is placed at x/y.
function BoneBullet:setAnchor(anchor)
    local origin_y = ANCHOR_ORIGINS[anchor]
    assert(origin_y ~= nil, "Bone anchor must be 'top', 'center', or 'bottom'")

    self.anchor = anchor
    self:setOrigin(0.5, origin_y)
end

-- Bones below the arena are hidden by it and cannot hit or graze the soul.
function BoneBullet:setLayer(layer)
    super.setLayer(self, layer)
    self.collidable = layer >= BATTLE_LAYERS["arena"]
end

return BoneBullet
