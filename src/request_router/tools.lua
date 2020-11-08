
local function build_options_response(supported_methods, response)
    response = response or {}
    local methods = {}
    for i,v in ipairs(supported_methods) do methods[i] = string.upper(v) end
    if not response.status then response.status = 200 end
    response['Allow'] = table.concat(methods, ',')
    return response
end

return {
    build_options_response = build_options_response,
}
