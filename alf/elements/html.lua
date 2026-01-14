local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Html: Container
---@operator call(...): Html
local Html = class(Element.Container)

---Init Html Container element
---@param attributes Attributes?
---@param content Content?
function Html:_init(attributes, content)
    self:super("html", attributes, content)
end

return Html
