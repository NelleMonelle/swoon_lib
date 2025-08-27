local character, super = Class("kris", true)

function character:init()
    super.init(self)

    self.can_swoon = false
end

return character