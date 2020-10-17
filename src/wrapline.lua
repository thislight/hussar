
local function call(wrapline, ...)
    local values = table.pack(...)
    for i, f in ipairs(wrapline) do
        values = table.pack(f(table.unpack(values)))
    end
    return table.unpack(values)
end

local OBJ_META = {
    __call = function(...)
        return call(...)
    end,
}

local function create()
    local new = {}
    setmetatable(new, OBJ_META)
    return new
end

local function wrap_context(f, ...)
    local args = table.pack(...)
    return function()
        return f(table.unpack(args))
    end
end

return {
    create = create,
    call = call,
    wrap_context = wrap_context,
}
