---@class Response
---@field content_type string
---@field headers {[string]: string}[]
---@field status_code number
---@field content string
local Response = {}
Response.__index = Response

setmetatable(Response, {
    ---An HTTP response
    ---The response object is the primary output interface for controllers.
    ---@param content string The content to return over the wire (default: "")
    ---@param content_type string The type of content data (default: "text/html")
    ---@param status_code number The status code (default: 200)
    ---@param headers table HTTP headers (default: {})
    ---@return Response
    __call = function(_, content, content_type, status_code, headers)
        return setmetatable({
            content = content or "",
            content_type = content_type or "text/html",
            status_code = status_code or 200,
            headers = headers or {},
        }, Response)
    end
})

---Send the response data over the ASGI interface
---@param send function The ASGI send callable
function Response.__call(self, send)
    -- prepend content type header
    table.insert(self.headers, 1, { "content-type", self.content_type })

    send({
        type = "http.response.start",
        status = self.status_code,
        headers = self.headers,
    })

    send({ type = "http.response.body", body = self.content })
end

return Response
