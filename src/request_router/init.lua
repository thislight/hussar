-- Copyright (C) 2020 thisLight
-- 
-- This file is part of hussar.
-- 
-- hussar is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- hussar is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with hussar.  If not, see <http://www.gnu.org/licenses/>.

local wrap_thread = require "hussar.wrap_thread"
local httputil = require "hussar.httputil"
local utils = require "hussar.utils"
local wrapline = require "hussar.wrapline"
local powerlog = require "powerlog"
local terr = require "hussar.terr"
local checkers = require "hussar.request_router.checkers"

local RequestRouter = {
    routes = {},
    logger = powerlog:create("hussar.request_router"),
}

function RequestRouter:clone_to(t)
    return utils.table_deep_copy(self, t)
end

function RequestRouter:create(routes)
    local newobj = self:clone_to {}
    newobj.wrapline = wrapline.create()
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

function RequestRouter:route(request, conn, frame, pubframe)
    for i, v in ipairs(self.routes) do
        local handler, checker = table.unpack(v)
        if checker(request, frame) then
            return handler
        end
    end
    return wrapline.wrap_context(self.not_found_error_handler, request, conn, frame, pubframe)
end

function RequestRouter.not_found_error_handler(request)
    return {
        status = 404,
        string.format("404 Not Found: %s", request.path)
    }
end

return RequestRouter
