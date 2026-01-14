local class = require("pl.class")

local Element = require("alf.elements.element")

---@class H5: Container
---@operator call(...): H5
local H5 = class(Element.Container)

---Init H5 Container element
---@param attributes Attributes?
---@param content Content?
function H5:_init(attributes, content)
    self:super("h5", attributes, content)
end

return H5
