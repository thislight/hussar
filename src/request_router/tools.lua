local httputil = require "hussar.httputil"
local headers = httputil.headers

local function build_options_response(supported_methods, response)
    response = response or {}
    local methods = {}
    for i,v in ipairs(supported_methods) do methods[i] = string.upper(v) end
    if not response.status then response.status = 200 end
    response['Allow'] = table.concat(methods, ',')
    return response
end

local function table_has_value(t, val)
    for i, v in ipairs(t) do
        if val == v then
            return true
        end
    end
    return false
end

local function is_cors_request(request)
    return headers.get_last_of(request.headers, 'Origin') ~= nil
end

local function cors_accept(request, options)
    local allow_methods = options.allow_methods or {}
    local allow_origins = options.allow_origins or {}
    local allow_all_origins = false
    if allow_origins[1] == '*' then
        allow_all_origins = true
    end
    local allow_credentials = options.allow_credentials
    local request_headers = request.headers
    if not table_has_value(allow_methods, string.lower(request.method)) then
        return false
    elseif not (allow_all_origins or table_has_value(allow_origins, string.lower(headers.get_last_of(request_headers, 'Origin')))) then
        return false
    elseif (not allow_credentials) and headers.get_last_of(request_headers, 'Set-Cookie') then
        return false
    end
    return true
end

local function map(fn, t)
    local result = {}
    for i=1,#t do
        result[i] = fn(t[i])
    end
    return result
end

local function cors_control(response, options, request)
    local allow_methods = options.allow_methods or {}
    local allow_origins = options.allow_origins or {}
    local allow_all_origins
    if allow_origins[1] == '*' then allow_all_origins = true end
    local expose_headers = options.expose_headers or {}
    local max_age = options.max_age
    local allow_credentials = options.allow_credentials
    local allow_headers = options.allow_headers or {}
    local request_headers = request.headers
    local origin = headers.get_last_of(request_headers, 'Origin')
    if origin then -- any CORS request include 'Origin' in header
        local concat = table.concat
        if #allow_methods > 0 then
            response['Access-Control-Allow-Methods'] = concat(map(string.upper, allow_methods), ',')
        end
        if allow_all_origins then
            response['Access-Control-Allow-Origin'] = '*'
        elseif table_has_value(allow_origins, origin) then
            response['Access-Control-Allow-Origin'] = origin
            headers.insert2response(response, 'Vary', 'Origin')
        end
        if #expose_headers > 0 then
            headers.insert2response(response, 'Access-Control-Expose-Headers', concat(expose_headers, ','))
        end
        if max_age then
            response['Access-Control-Max-Age'] = max_age
        end
        if allow_credentials then
            response['Access-Control-Allow-Credentials'] = 'true'
        end
        if #allow_headers > 0 then
            response['Access-Control-Allow-Headers'] = concat(allow_headers, ',')
        end
    end
    return response
end

local function cors_wrapper(options)
    return function(handler)
        return function(request, frame, pubframe)
            if is_cors_request(request) and cors_accept(request, options) then
                local response = handler(request, frame, pubframe)
                return cors_control(response, options, request)
            elseif options.error_handler then
                local response = options.error_handler(request, frame, pubframe)
                return cors_control(response, options, request)
            else
                return cors_control({
                    status = 400,
                    "CORS Error"
                }, options, request)
            end
        end
    end
end

return {
    build_options_response = build_options_response,
    cors_accept = cors_accept,
    cors_control = cors_control,
    is_cors_request = is_cors_request,
    cors_wrapper = cors_wrapper,
}
