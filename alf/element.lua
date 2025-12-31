local class = require("pl.class")

---@class Element An HTML element
---@field render fun(self):string
---@field class_of fun(self, obj:any):boolean
local Element = class()

---An HTML element
---@param tag string
---@param content string|Element|fun():string|nil
---@param attributes [string]|nil
function Element:_init(tag, content, attributes)
    self.tag = assert(tag)
    self.content = content
    self.attributes = attributes or {}
end

---Render HTML including recursive inner elements
---@return string
function Element:render()
    local html = {}
    table.insert(html, string.format("<%s ", self.tag))
    for _, attribute in ipairs(self.attributes) do
        table.insert(html, string.format("%s ", attribute))
    end
    table.insert(html, ">")
    if type(self.content) == "string" then
        table.insert(html, self.content)
    elseif Element:class_of(self.content) then
        table.insert(html, self.content:render())
    elseif type(self.content) == "function" then
        table.insert(html, self.content())
    end
    table.insert(html, string.format("</%s>", self.tag))
    return table.concat(html)
end

return Element
