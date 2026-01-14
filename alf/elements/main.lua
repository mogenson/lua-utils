local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Main: Container
---@operator call(...): Main
local Main = class(Element.Container)

---Init Main Container element
---@param attributes Attributes?
---@param content Content?
function Main:_init(attributes, content)
    self:super("main", attributes, content)
end

return Main
