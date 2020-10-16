local format = string.format

local ERR_META = {
    __tostring = function(self)
        return format("kind=%s type=%s reason=%s", self.kind, self.type,
                      self.reason)
    end
}

local function createE(object_kind, type, reason, extra_data)
    local t = {k = object_kind, t = type, r = reason, e = extra_data, __TERR__ = true}
    setmetatable(t, ERR_META)
    return t
end

local function errorT(...)
    local arg_count = select("#", ...)
    if arg_count > 1 then
        error(createE(...), 2)
    elseif type(select(1, ...)) == "string" then
        error(createE(...))
    else
        error(...)
    end
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
        local handler = match_kind(e, gotable)
        if handler then
            return handler(e, gotable)
        elseif rethrow_if_no_match then
            errorT(e)
        end
    else
        return e
    end
end

return {
    createE = createE,
    errorT = errorT,
    matchE = matchE,
}
