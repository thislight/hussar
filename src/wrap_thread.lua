
local create = coroutine.create
local resume = coroutine.resume

return function(func)
    return function(...)
        local new_thread = create(func)
        resume(new_thread, ...)
        return new_thread
    end
end
