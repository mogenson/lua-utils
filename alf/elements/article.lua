local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Article: Container
---@operator call(...): Article
local Article = class(Element.Container)

---Init Article Container element
---@param attributes Attributes?
---@param content Content?
---@diagnostic disable-next-line duplicate-set-field
function Article:_init(attributes, content)
    self:super("article", attributes, content)
end

return Article
