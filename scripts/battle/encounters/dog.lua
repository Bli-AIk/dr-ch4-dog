
local Dog, super = Class(Encounter)

function Dog:init()
    super.init(self)

    -- Text displayed at the bottom of the screen at the start of the encounter
    self.text = Game:loc("encounter_dog_start")

    -- Battle music ("battle" is rude buster)
    self.music = "dog_buster"
    -- Enables the purple grid battle background
    self.background = true

    -- Add the dummy enemy to the encounter
    self:addEnemy("dog")

    --- Uncomment this line to add another!
    --self:addEnemy("dummy")
end

function Dog:onBattleInit()
    Game.battle.music:setVolume(0.5)
end

return Dog
