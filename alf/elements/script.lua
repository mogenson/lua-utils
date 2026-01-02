local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Script: Container
local Script = class(Element.Container)

---Init Script Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Script:_init(attributes, content)
    self:super("script", attributes, content)
end

return Script
