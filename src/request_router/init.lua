local wrap_thread = require "hussar.wrap_thread"
local httputil = require "hussar.httputil"
local utils = require "hussar.utils"
local wrapline = require "hussar.wrapline"
local powerlog = require "powerlog"
local terr = require "hussar.terr"
local checkers = require "hussar.request_router.checkers"

local wait_for_request = httputil.wait_for_request

local RequestRouter = {
    routes = {},
    logger = powerlog:create("hussar.request_router")
}

local function wrap_error_handler(f, error_handler)
    return function(...) xpcall(f, wrapline.wrap_context(error_handler, ...), ...) end
end

local function make_handler(rules_f, error_handler)
    return wrap_thread(wrap_error_handler(
                           function(conn, frame, pubframe)
            local request = wait_for_request(conn)
            frame.connection = conn
            frame.request = request
            local user_handler = rules_f(request)
            local result = user_handler(request, frame, pubframe)
            if result and conn:is_alive() then
                httputil.respond(conn, result)
            end
            if (not conn:is_keep_alive()) and (conn:is_alive()) then
                conn:close()
            end
        end, error_handler))
end

function RequestRouter:clone_to(t)
    return utils.table_deep_copy(self, t)
end

function RequestRouter:create(routes)
    local newobj = self:clone_to {}
    newobj:add_routes(routes or {})
    return newobj
end

function RequestRouter:add_routes(routes)
    for _, v in ipairs(routes) do
        local checker, handler = table.unpack(v)
        if type(checker) == 'string' then
            checker = checkers.PATH(checker)
        end
        table.insert(self.routes, {handler, checker})
    end
end

function RequestRouter:attach(hussar)
    hussar.handler = make_handler(function(request) self:route(request) end, wrapline.wrap_context(self.error_handler, self))
end

function RequestRouter:route(request)
    for i, v in ipairs(self.routes) do
        local handler, checker = table.unpack(v)
        if checker(request) then
            return handler
        end
    end
    return self.not_found_error_handler
end

function RequestRouter.not_found_error_handler(request, frame, pubframe)
    return {
        status = 404,
        string.format("404 Not Found: %s", request.path)
    }
end

function RequestRouter:error_handler(e, conn, frame, pubframe)
    if terr.is(e) then
        if frame.request then
            e.e = e.e or {}
            if type(e.e) == 'table' then
                e.e.request = frame.request
            end
        end
    end
    httputil.respond(conn, {status=500})
    self.logger:warn("error while handler runing", e)
end
