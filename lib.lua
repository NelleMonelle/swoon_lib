local lib = {}

function lib:init()

    Utils.hook(Encounter, "init", function(orig, self)
        orig(self)
        self.swoon = false
        self.autoheal_disabled = false
    end)

    Utils.hook(Battle, "canSwoon", function(orig, self)
        return self.encounter.swoon
    end)

    Utils.hook(PartyMember, "init", function(orig, self)
        orig(self)
        self.can_swoon = true
    end)

    Utils.hook(PartyMember, "canSwoon", function(orig, self)
        return self.can_swoon
    end)

    Utils.hook(PartyBattler, "hurt", function(orig, self, amount, exact, color, options)
        options = options or {}

        if not options["all"] then
            Assets.playSound("hurt")
            if not exact then
                amount = self:calculateDamage(amount)
                if self.defending then
                    amount = math.ceil((2 * amount) / 3)
                end
                -- we don't have elements right now
                local element = 0
                amount = math.ceil((amount * self:getElementReduction(element)))
            end

            self:removeHealth(amount)
        else
            -- We're targeting everyone.
            if not exact then
                amount = self:calculateDamage(amount)
                -- we don't have elements right now
                local element = 0
                amount = math.ceil((amount * self:getElementReduction(element)))

                if self.defending then
                    amount = math.ceil((3 * amount) / 4) -- Slightly different than the above
                end
            end

            self:removeHealthBroken(amount) -- Use a separate function for cleanliness
        end

        if (self.chara:getHealth() <= 0) then
            if Game.battle:canSwoon() and self.chara:canSwoon() then
                self:statusMessage("msg", "swoon", color, true)
            else
                self:statusMessage("msg", "down", color, true)
            end
        else
            self:statusMessage("damage", amount, color, true)
        end

        self.hurt_timer = 0
        Game.battle:shakeCamera(4)

        if (not self.defending) and (not self.is_down) then
            self.sleeping = false
            self.hurting = true
            self:toggleOverlay(true)
            self.overlay_sprite:setAnimation("battle/hurt", function()
                if self.hurting then
                    self.hurting = false
                    self:toggleOverlay(false)
                end
            end)
            if not self.overlay_sprite.anim_frames then -- backup if the ID doesn't animate, so it doesn't get stuck with the hurt animation
                Game.battle.timer:after(0.5, function()
                    if self.hurting then
                        self.hurting = false
                        self:toggleOverlay(false)
                    end
                end)
            end
        end
    end)

    Utils.hook(PartyBattler, "removeHealth", function(orig, self, amount)
        if (self.chara:getHealth() <= 0) then
            amount = Utils.round(amount / 4)
            self.chara:setHealth(self.chara:getHealth() - amount)
        else
            self.chara:setHealth(self.chara:getHealth() - amount)
            if (self.chara:getHealth() <= 0) then
                if Game.battle:canSwoon() and self.chara:canSwoon() then
                    self.chara:setHealth(-999)
                else
                    amount = math.abs((self.chara:getHealth() - (self.chara:getStat("health") / 2)))
                    self.chara:setHealth(Utils.round(((-self.chara:getStat("health")) / 2)))
                end
            end
        end
        self:checkHealth()
    end)

    Utils.hook(PartyBattler, "down", function(orig, self)
        self.is_down = true
        self.sleeping = false
        self.hurting = false
        self:toggleOverlay(true)
        if Game.battle:canSwoon() and self.chara:canSwoon() then
            if not self.overlay_sprite:setAnimation("battle/swoon") then
                self.overlay_sprite:setAnimation("battle/defeat")
            end
        else
            self.overlay_sprite:setAnimation("battle/defeat")
        end
        if self.action then
            Game.battle:removeAction(Game.battle:getPartyIndex(self.chara.id))
        end
        Game.battle:checkGameOver()
    end)

    Utils.hook(PartyMember, "canAutoHeal", function(orig, self)
        if Game.battle.encounter.autoheal_disabled then
            return false
        end
        return true
    end)
end

return lib