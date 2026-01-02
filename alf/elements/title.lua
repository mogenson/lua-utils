local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Title: Container
local Title = class(Element.Container)

---Init Title Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Title:_init(attributes, content)
    self:super("title", attributes, content)
end

return Title
