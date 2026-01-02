local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Audio: Container
local Audio = class(Element.Container)

---Init Audio Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Audio:_init(attributes, content)
    self:super("audio", attributes, content)
end

return Audio
