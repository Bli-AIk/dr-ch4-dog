local Dog, super = Class(EnemyBattler)

function Dog:init()
    super.init(self)

    self:applyLocalization()
    self:setActor("dog")

    -- Enemy health
    self.max_health = 450
    self.health = 450
    -- Enemy attack (determines bullet damage)
    self.attack = 4
    -- Enemy defense (usually 0)
    self.defense = 0
    -- Enemy reward
    self.money = 100

    -- Mercy given when sparing this enemy before its spareable (20% for basic enemies)
    self.spare_points = 20

    -- List of possible wave ids, randomly picked each turn
    self.waves = {
        "basic",
        "aiming",
        "movingarena"
    }

    -- Dialogue randomly displayed in the enemy's speech bubble
    self.dialogue = {
        "..."
    }

    -- Register the single-character and party versions of "Pet".
    self:registerAct(self.act_pet, self.act_pet_description)
    self:registerAct(self.act_pet_party, self.act_pet_description, {"susie", "ralsei"})
    -- Register the party act "Tell Joke".
    self:registerAct(self.act_tell_joke, self.act_tell_joke_description, {"susie", "ralsei"}, 100)
end

function Dog:applyLocalization(update_acts)
    local old_check = self.act_check
    local old_pet = self.act_pet
    local old_pet_party = self.act_pet_party
    local old_tell_joke = self.act_tell_joke

    -- Enemy name
    self.name = Game:locText("[name:dog]")
    -- Check text (automatically has "ENEMY NAME - " at the start)
    self.check = Game:loc("enemy_dog_check")

    -- Text randomly displayed at the bottom of the screen each turn
    self.text = {
        Game:loc("enemy_dog_turn_1"),
        Game:loc("enemy_dog_turn_2"),
        Game:loc("enemy_dog_turn_3"),
    }
    -- Text displayed at the bottom of the screen when the enemy has low health
    self.low_health_text = Game:loc("enemy_dog_low_health")

    self.act_check = Game:loc("act_check")
    self.act_pet = Game:loc("act_dog_pet")
    self.act_pet_party = self.act_pet
    self.act_pet_description = Game:loc("act_dog_pet_description")
    self.act_tell_joke = Game:loc("act_dog_tell_joke")
    self.act_tell_joke_description = Game:loc("act_dog_tell_joke_description")

    if self.acts and self.acts[1] then
        self.acts[1].name = self.act_check
    end

    if update_acts then
        for _, act in ipairs(self.acts or {}) do
            if act.name == old_check then
                act.name = self.act_check
            elseif act.name == old_pet or act.name == old_pet_party then
                act.name = self.act_pet
                act.description = self.act_pet_description
            elseif act.name == old_tell_joke then
                act.name = self.act_tell_joke
                act.description = self.act_tell_joke_description
            end
        end
    end
end

function Dog:onAct(battler, name)
    if name == self.act_check then
        return super.onAct(self, battler, "Check")

    elseif name == self.act_pet then
        local action = Game.battle:getCurrentAction()
        if action and action.party and #action.party > 0 then
            return Game:loc("act_dog_pet_party_text")
        end
        return Game:loc("act_dog_pet_text")

    elseif name == self.act_tell_joke then
        Game.battle:startActCutscene("dog", "tell_joke")
        return

    elseif name == "Standard" then --X-Action
        return Game:loc("act_dog_standard", {
            name = battler.chara:getName()
        })
    end

    -- If the act is none of the above, run the base onAct function
    -- (this handles the Check act)
    return super.onAct(self, battler, name)
end

return Dog
