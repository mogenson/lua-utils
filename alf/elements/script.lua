local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Script: Container
---@operator call(...): Script
local Script = class(Element.Container)

---Init Script Container element
---@param attributes Attributes?
---@param content Content?
function Script:_init(attributes, content)
    self:super("script", attributes, content)
end

return Script
