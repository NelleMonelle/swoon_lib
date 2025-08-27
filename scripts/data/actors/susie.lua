local actor, super = Class("susie", true)

function actor:init()
    super.init(self)

    Utils.merge(self.animations, {
        ["battle/swoon"] = {"fell", 0.2, false},
    }, false)

end

return actor