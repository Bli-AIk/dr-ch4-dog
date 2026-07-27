local actor, super = Class(Actor, "dog")

function actor:init()
    super.init(self)

    -- Display name (optional)
    self.name = "Annoying Dog"

    -- Match the largest frame in the dog animations (idle_2 is 22x19).
    self.width = 22
    self.height = 19

    -- Hitbox for this actor in the overworld (optional, uses width and height by default)
    self.hitbox = { 0, 5, 22, 14 }

    -- Color for this actor used in outline areas (optional, defaults to red)
    self.color = { 1, 0, 0 }

    -- Whether this actor flips horizontally (optional, values are "right" or "left", indicating the flip direction)
    self.flip = nil

    -- Path to this actor's sprites (defaults to "")
    self.path = "enemies/dog"
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    self.default = "idle"

    -- Sound to play when this actor speaks (optional)
    self.voice = nil
    -- Path to this actor's portrait for dialogue (optional)
    self.portrait_path = nil
    -- Offset position for this actor's portrait (optional)
    self.portrait_offset = nil

    -- Whether this actor as a follower will blush when close to the player
    self.can_blush = false

    -- Table of talk sprites and their talk speeds (default 0.25)
    self.talk_sprites = {
        ["speak/"] = 1 / 6,
    }

    -- Table of sprite animations
    self.animations = {
        -- Looping animation with 0.25 seconds between each frame
        -- (even though there's only 1 idle frame)
        ["idle"] = { "idle/idle", 0.25, true },
        ["speak"] = { "speak/", 1 / 6, true },
        ["car"] = { "car/", 1 / 6, true },
        ["spin"] = { "spin/spin", 1 / 30, false, next = "idle" },
    }

    -- Table of sprite offsets (indexed by sprite name)
    self.offsets = {
        -- The actor dimensions cover all animation frames, so no offset is needed.
        ["idle"] = { 0, 0 },
        ["car/"] = { -9, -23 },
    }
end

function actor:onTalkStart(text, sprite)
    if sprite.sprite == "idle/idle" then
        sprite:setAnimation("speak")
    end
end

function actor:onTalkEnd(text, sprite)
    if sprite.sprite == "speak/" then
        sprite:setAnimation("idle")
    end
end

return actor
