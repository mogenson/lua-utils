local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Mark: Container
---@operator call(...): Mark
local Mark = class(Element.Container)

---Init Mark Container element
---@param attributes Attributes?
---@param content Content?
function Mark:_init(attributes, content)
    self:super("mark", attributes, content)
end

return Mark
