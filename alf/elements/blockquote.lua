local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Blockquote: Container
---@operator call(...): Blockquote
local Blockquote = class(Element.Container)

---Init Blockquote Container element
---@param attributes Attributes?
---@param content Content?
function Blockquote:_init(attributes, content)
    self:super("blockquote", attributes, content)
end

return Blockquote
