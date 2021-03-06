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

local Silva = require "Silva"
local httputil = require "hussar.httputil"

local headers = httputil.headers

local function create(host, path, extra_check, host_match_kind, path_match_kind)
    local path_matcher, host_matcher
    if host then
        host_matcher = Silva(host, host_match_kind or 'identity')
    end
    if path then
        path_matcher = Silva(path, path_match_kind or 'lua')
    end
    return function(request, frame)
        if host then
            local host_value = headers.get_last_of(request.headers, 'Host')
            local host_match = host_matcher(host_value)
            if not host_match then
                return false
            elseif frame then
                frame.host_match = host_match
            end
        end
        if path then
            local path_match = path_matcher(request.path)
            if not path_match then
                return false
            elseif frame then
                frame.path_match = path_match
            end
        end
        if extra_check then
            return extra_check(request, frame)
        else
            return true
        end
    end
end

local function HOST_AND_PATH(host, path, host_match_kind, path_match_kind)
    return create(host, path, nil, host_match_kind, path_match_kind)
end

local function PATH(path, match_kind)
    return create(nil, path, nil, nil, match_kind)
end

local function HOST(host, match_kind)
    return create(host, nil, nil, match_kind)
end

local function CUSTOM(checker)
    return create(nil, nil, checker)
end

return {
    create = create,
    HOST_AND_PATH = HOST_AND_PATH,
    PATH = PATH,
    HOST = HOST,
    CUSTOM = CUSTOM,
}
