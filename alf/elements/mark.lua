local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Mark: Container
local Mark = class(Element.Container)

---Init Mark Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Mark:_init(attributes, content)
    self:super("mark", attributes, content)
end

return Mark
