local compress_response = require("hussar.httputil").compress_response
local build_response = require("hussar.httputil").response

return function(handler)
    return function(request, frame, pubframe)
        local conn = frame.connection
        local result = handler(request, frame, pubframe)
        if result then
            local response = build_response(result)
            if pubframe.auto_write_compress then
                compress_response(response)
            end
            conn:write(response)
        end
        conn:close()
    end
end
