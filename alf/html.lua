-- from https://riki.house/lua-html

---@alias HtmlContent string|Html|table

---@class Html
---@field text string
local Html = {}

---@class html
---@overload fun(def: HtmlContent): Html
local html = {}
setmetatable(html --[[@as table]], html --[[@as metatable]])

local escape_subs = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#39;",
}

---Escapes HTML special characters in a string.
---@param str string The string to escape.
---@return string The escaped string.
local function escape_html(str)
    return (str:gsub("([&<>\"'])", escape_subs))
end

---Writes multiple values into a table.
---@param t any[] The table to write to.
---@param ... any The values to insert into the table.
local function write(t, ...)
    local n = select('#', ...)
    for i = 1, n do
        table.insert(t, (select(i, ...)))
    end
end

---Creates a new Html object representing raw HTML text.
---@param text string The raw HTML text.
---@return Html A new Html object.
function html.Html(text)
    assert(type(text) == "string", "html.Html expects a string")
    local obj = { text = text }
    setmetatable(obj, Html)
    return obj --[[@as Html]]
end

---Returns the string representation of the Html object.
---@return string The raw HTML text.
function Html:__tostring()
    return self.text
end

local void_elements = {
    area = true,
    base = true,
    br = true,
    col = true,
    embed = true,
    hr = true,
    img = true,
    input = true,
    link = true,
    meta = true,
    param = true,
    source = true,
    track = true,
    wbr = true,
}

---Comparator for HTML attributes to ensure stable output order.
---@param a any[] The first attribute pair {key, value}.
---@param b any[] The second attribute pair {key, value}.
---@return boolean True if a should come before b.
local function attr_cmp(a, b)
    return a[1] < b[1]
end

---Recursively writes children elements into the parent element list.
---@param el any[] The parent element list (table of strings).
---@param def HtmlContent The child definition(s).
local function write_children(el, def)
    if type(def) == "string" then
        table.insert(el, escape_html(def))
    elseif type(def) == "table" and getmetatable(def) == Html then
        ---@cast def Html
        table.insert(el, def.text)
    elseif type(def) == "table" then
        ---@cast def any[]
        for _, child in ipairs(def) do
            write_children(el, child)
        end
    end
end

---Creates an HTML element of a given kind with attributes and children.
---@param kind string The HTML tag name (e.g., "div", "span").
---@param def? HtmlContent The attributes and children of the element.
---@return Html The resulting Html object.
function html.Element(kind, def)
    def = type(def) == "string" and { def } or def or {}

    local attr = {} ---@type any[][]
    for k, v in pairs(def) do
        if type(k) == "string" then
            table.insert(attr, { k:gsub("_", "-"), tostring(v) })
        end
    end
    table.sort(attr, attr_cmp)

    -- open tag
    local el = { "<", kind }
    for _, a in ipairs(attr) do
        write(el, " ", a[1], '="', escape_html(a[2]), '"')
    end
    table.insert(el, ">")

    if void_elements[kind] then
        return html.Html(table.concat(el))
    end

    -- children
    write_children(el, def)

    -- close tag
    write(el, "</", kind, ">")

    return html.Html(table.concat(el))
end

---Creates an HTML document with a doctype.
---@param def? HtmlContent The content of the html element.
---@return Html The resulting Html object.
function html.Document(def)
    return html.Html("<!doctype html>" .. tostring(html.Element("html", def)))
end

---Dynamic handler for tag names accessed as properties on the html module.
---@param t html The html module table.
---@param key string The tag name.
---@return fun(def: HtmlContent): Html A function that creates the requested element.
function html.__index(t, key)
    local tag = key:gsub("_", "-")
    ---@param def HtmlContent
    ---@return Html
    local function thunk(def)
        return html.Element(tag, def)
    end
    rawset(t --[[@as table]], key, thunk)
    -- memoise for future use; __index will not be called then
    return thunk
end

return html
