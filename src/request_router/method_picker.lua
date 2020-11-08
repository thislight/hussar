local respond = require('httputil').respond
local lower = string.lower

return function(options)
    return function(request, frame, ...)
        local method = lower(request.method)
        if options[method] then
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
