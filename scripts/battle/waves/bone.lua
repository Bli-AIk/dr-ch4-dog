---@class Bone : Wave
local Bone, super = Class(Wave)

function Bone:onStart()
    local arena = Game.battle.arena
    local center_x, center_y = arena:getCenter()
    local x_margin = 20

    -- All three bones share a y-coordinate, while their anchors place them differently around it.
    local bones = {
        { arena.left + x_margin, "top" },
        { center_x, "center" },
        { arena.right - x_margin, "bottom" },
    }

    for _, bone in ipairs(bones) do
        self:spawnBullet("pap_bone", bone[1], center_y, 40, bone[2])
    end
end

return Bone
