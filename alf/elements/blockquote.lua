local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Blockquote: Container
local Blockquote = class(Element.Container)

---Init Blockquote Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Blockquote:_init(attributes, content)
    self:super("blockquote", attributes, content)
end

return Blockquote
