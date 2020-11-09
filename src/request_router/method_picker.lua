local respond = require('hussar.httputil').respond
local tools = require 'hussar.request_router.tools'
local lower = string.lower
local build_options_response = tools.build_options_response

return function(options)
    local supported_methods = {}
    local has_option = false
    for k, _ in pairs(options) do
        if k ~= 'default' then
            supported_methods[#supported_methods+1] = k
            if k == 'options' then
                has_option = true
            end
        end
    end
    if not has_option then
        supported_methods[#supported_methods+1] = 'options'
    end
    return function(request, frame, ...)
        local method = lower(request.method)
        if method == 'options' then
            if options.options then
                return options.options(request, ...)
            else
                respond(frame.connection, build_options_response(supported_methods))
            end
        elseif options[method] then
            return options[method](request, ...)
        elseif options.default then
            return options.default(request, ...)
        else
            respond(frame.connection, {
                status = 404,
            })
        end
    end
end
