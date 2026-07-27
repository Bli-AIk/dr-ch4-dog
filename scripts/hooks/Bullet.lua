---@class Bullet
local Bullet, super = HookSystem.hookScript(Bullet)

function Bullet:canGraze()
    if self:isBullet("gaster_blaster") then
        return true
    end
    return super.canGraze(self)
end

function Bullet:getGrazeTension()
    if self:isBullet("gaster_blaster") then
        if self.grazed then
            return 1 / DT
        end
        return 1
    end
    return super.getGrazeTension(self)
end

function Bullet:getDamage()
    if self:isBullet("gaster_blaster") then
        return 1
    end
    return super.getDamage(self)
end

function Bullet:getInvulnTime()
    if self:isBullet("gaster_blaster") then
        return 1 / 30
    end
    return super.getInvulnTime(self)
end

return Bullet
