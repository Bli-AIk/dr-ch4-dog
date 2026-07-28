local Dog, super = Class(EnemyBattler)

function Dog:init()
    super.init(self)

    self:applyLocalization()
    self:setActor("dog")

    self.joke_completed = false
    self.special_pet_completed = false

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

    -- Waves used after the first three turns, which are selected in order below.
    self.waves = {
        "bone",
        "gb",
        "car"
    }

    -- The dog only speaks through the one-turn override set after Tell Joke.
    self.dialogue = {}

    -- Register the single-character and party versions of "Pet".
    self:registerAct(self.act_pet, self.act_pet_description)
    self:registerAct(self.act_pet_party, self.act_pet_description, {"susie", "ralsei"})
    -- Register the party act "Tell Joke".
    self:registerAct(self.act_tell_joke, self.act_tell_joke_description, {"susie", "ralsei"}, 100)
end

-- The dog dodges every attack instead of taking damage.
function Dog:getAttackDamage(damage, battler, points)
    return 0
end

function Dog:selectWave()
    local fixed_waves = {
        "bone",
        "gb",
        "car"
    }
    local turn = Game.battle.turn_count

    if turn >= 1 and turn <= #fixed_waves then
        self.selected_wave = fixed_waves[turn]
        return self.selected_wave
    end

    return super.selectWave(self)
end

function Dog:onBubbleSpawn(bubble)
    bubble.text.talk_sprite = self:getActiveSprite()
end

function Dog:getEncounterText()
    if self.gb_narration_pending then
        self.gb_narration_pending = nil

        local party_health = self.gb_party_health
        local someone_was_down = self.gb_party_was_down
        self.gb_party_health = nil
        self.gb_party_was_down = nil

        if someone_was_down then
            return Game:loc("battle_dog_gb_kris_downed"), "teeth_b", "susie"
        end

        local damaged_battlers = {}
        for _, battler in ipairs(Game.battle.party) do
            local starting_health = party_health and party_health[battler.chara.id]
            if starting_health and battler.chara:getHealth() < starting_health then
                table.insert(damaged_battlers, battler)
            end
        end

        if #damaged_battlers == 1 and damaged_battlers[1].chara.id == "susie" then
            return Game:loc("battle_dog_gb_kris_downed"), "teeth_b", "susie"
        elseif #damaged_battlers > 0 then
            local lowest_health_battler = nil
            for _, battler in ipairs(Game.battle.party) do
                if battler.chara.id ~= "susie"
                    and (not lowest_health_battler
                        or battler.chara:getHealth() < lowest_health_battler.chara:getHealth())
                then
                    lowest_health_battler = battler
                end
            end

            local name = lowest_health_battler
                and Game:locText("[name:" .. lowest_health_battler.chara.id .. "]")
                or Game:locText("[name:kris]")
            return Game:loc("battle_dog_gb_damaged", {name = name}), "intense_angry", "susie"
        else
            return Game:loc("battle_dog_gb_undamaged"), "surprise_smile", "susie"
        end
    end

    return super.getEncounterText(self)
end

function Dog:onTurnEnd()
    if self.selected_wave ~= "gb" then
        self.gb_narration_pending = false
        self.gb_party_health = nil
        self.gb_party_was_down = nil
        return
    end

    local susie = Game.battle:getPartyBattler("susie")
    self.gb_party_was_down = false
    for _, battler in ipairs(Game.battle.party) do
        if battler.is_down then
            self.gb_party_was_down = true
            break
        end
    end

    self.gb_narration_pending = susie and not susie.is_down or false
    if not self.gb_narration_pending then
        self.gb_party_health = nil
        self.gb_party_was_down = nil
    end
end

function Dog:hurt(amount, battler, on_defeat, color, show_status, attacked)
    local sprite = self:getActiveSprite()
    if not sprite or sprite.anim ~= "spin" then
        self:setAnimation("spin")
    end
    if show_status ~= false then
        self:statusMessage("msg", "miss_gold")
    end
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
            if self.joke_completed and not self.special_pet_completed then
                self.special_pet_completed = true
                Game.battle:startActCutscene("dog", "pet_party_special")
                return
            end

            Game.battle:startActCutscene(function(cutscene)
                cutscene:text(Game:loc("act_dog_pet_party_text"), {
                    functions = {
                        dog_pet_miss = function()
                            self:statusMessage("msg", "miss_gold")
                        end
                    }
                })
            end)
            return
        end
        return Game:loc("act_dog_pet_text")

    elseif name == self.act_tell_joke then
        local cutscene = Game.battle:startActCutscene("dog", "tell_joke")
        cutscene:after(function()
            self.joke_completed = true
            self.dialogue_override = "[instant][sound:voice/sans]"
                .. Game:loc("battle_dog_dialogue")
        end)
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
