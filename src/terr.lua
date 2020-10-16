local format = string.format

local function topstring(t)
    if type(t) == 'table' then
        local buffer =  {}
        for k,v in pairs(t) do
            table.insert(buffer, string.format("%s=%s", topstring(k), topstring(v)))
        end
        return '{'..table.concat(buffer, ',')..'}'
    elseif type(t) == 'string' then
        return '"'..t..'"'
    elseif type(t) == 'number' then
        return tostring(t)
    else
        return '<'..tostring(t)..'>'
    end
end

local ERR_META = {
    __tostring = function(self)
        return format("kind=%s type=%s reason=%s\n%s\nextra data: %s", self.k, self.t,
                      self.r, self.b or "no traceback", topstring(self.e))
    end
}

local function createE(object_kind, type, reason, extra_data, traceback_level)
    traceback_level = traceback_level or 1
    traceback_level = traceback_level + 1
    local traceback
    if debug then
        traceback = debug.traceback(nil, traceback_level)
    end
    local t = {k = object_kind, t = type, r = reason, e = extra_data, __TERR__ = true, b = traceback}
    setmetatable(t, ERR_META)
    return t
end

local function errorT(kind, type, reason, extra_data, level)
    error(createE(kind, type, reason, extra_data, (level or 1)+1))
end

local function match_reason(e, gotable)
    if gotable[e.r] then
        return gotable[e.r]
    else
        return gotable._all
    end
end

local function match_type(e, gotable)
    local target = gotable[e.t]
    if target then
        if type(target) == 'table' then
            return match_reason(e, gotable)
        else
            return target
        end
    else
        return gotable._all
    end
end

local function match_kind(e, gotable)
    local target = gotable[e.k]
    if target then
        if type(target) == 'table' then
            return match_type(e, gotable)
        else
            return target
        end
    else
        return gotable._all
    end
end

local function matchE(e, gotable, rethrow_if_no_match)
    if rethrow_if_no_match == nil then
        rethrow_if_no_match = true
    end
    if e.__TERR__ then
        local handler
        handler = match_reason(e, gotable)
        handler = match_type(e, gotable)
        handler = match_kind(e, gotable)
        if handler then
            return handler(e, gotable)
        elseif rethrow_if_no_match then
            errorT(e)
        end
    else
        return e
    end
end

local function pcallT(f, ...)
    local argcount = select("#", ...)
    local args = table.pack(...)
    table.remove(args, argcount)
    local gotable = select(argcount, ...)
    local result = table.pack(pcall(f, table.unpack(args)))
    if not result[1] then
        result[2] = matchE(result[2], gotable)
    end
    table.remove(result, 1)
    return table.unpack(result)
end

return {
    createE = createE,
    errorT = errorT,
    matchE = matchE,
    pcallT = pcallT,
}
