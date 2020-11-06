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

local away = require "away"
local utils = require "hussar.utils"
local lphr = require "lphr.r2"
local pathetic = require "pathetic"
local terr = require "hussar.terr"

local get_current_thread = away.get_current_thread

local function require_field(t, key)
    if t[key] == nil then
        error(string.format("field '%s' is required in table", key), 2)
    end
end

local default_methods = {
    'GET', 'POST', 'OPTIONS', 'PUT', 'DELETE', 'CONNECT', 'HEAD', 'PATCH', 'TRACE',
}

local response_code2status_table = {
    [100] = "Continue",
    [101] = "Switching Protocols",
    [102] = "Processing",
    [200] = "OK",
    [201] = "Created",
    [202] = "Accepted",
    [203] = "Non-Authoritative Information",
    [204] = "No Content",
    [205] = "Reset Content",
    [206] = "Partial Content",
    [207] = "Multi-Status",
    [208] = "Already Reported",
    [209] = "IM Used",
    [300] = "Multiple Choices",
    [301] = "Moved Permanently",
    [302] = "Found",
    [303] = "See Other",
    [304] = "Not Modified",
    [305] = "Use Proxy",
    [306] = "Switch Proxy",
    [307] = "Temporary Redirect",
    [308] = "Permanent Redirect",
    [400] = "Bad Request",
    [401] = "Unauthorized",
    [402] = "Payment Required",
    [403] = "Forbidden",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [406] = "Not Acceptable",
    [407] = "Proxy Authentication Required",
    [408] = "Request Timeout",
    [409] = "Conflict",
    [410] = "Gone",
    [411] = "Length Required",
    [412] = "Precondition Failed",
    [413] = "Request Entity Too Large",
    [414] = "Request-URI Too Long",
    [415] = "Unsupported Media Type",
    [416] = "Requested Range Not Satisfiable",
    [417] = "Expectation Failed",
    [418] = "I'm a teapot",
    [421] = "Misdirected Request",
    [422] = "Unprocessable Entity",
    [423] = "Locked",
    [424] = "Failed Dependency",
    [425] = "Too Early",
    [426] = "Upgrade Required",
    [428] = "Precondition Required",
    [429] = "Too Many Requests",
    [431] = "Request Header Fields Too Large",
    [444] = "No Response", -- non-official status code, introduced by nginx
    [451] = "Unavailable For Legal Reasons",
    [500] = "Internal Server Error",
    [501] = "Not Implemented",
    [502] = "Bad Gateway",
    [503] = "Service Unavailable",
    [504] = "Gateway Timeout",
    [505] = "HTTP Version Not Supported",
    [506] = "Variant Also Negotiate",
    [507] = "Insufficient Storage",
    [508] = "Loop Detected",
    [510] = "Not Extended",
    [511] = "Network Authentication Required",
    [996] = "ICU Required",
}

local function get_response_status2code_table()
    local new_t = {}
    for k, v in pairs(response_code2status_table) do
        new_t[v] = k
    end
    return new_t
end

local response_status2code_table = get_response_status2code_table()

local function build_request(t)
    require_field(t, 'method')
    require_field(t, 'path')
    t.minor_version = t.minor_version or 1
    local result_t = {}
    if #t > 0 and ((not t['Content-Length']) and (not t['Content-Length'])) then
        t['Content-Length'] = tostring(#t[1])
    end
    if #t > 0 and not t['Content-Type'] then
        t['Content-Type'] = 'plain/text'
    end
    table.insert(result_t, string.format("%s %s HTTP/1.%d", string.upper(t.method), t.path, t.minor_version))
    for k, v in pairs(t) do
        if not (k == 'method' or k == 'path' or k == 'minor_version') then
            table.insert(result_t, string.format("%s: %s", k, v))
        end
    end
    table.insert(result_t, "")
    if #t > 0 then
        local transfer_encoding = t['Transfer-Encoding']
        if transfer_encoding and string.lower(transfer_encoding) == "chunked" then
            table.insert(tostring(#t[1]))
        end
        table.insert(result_t, t[1])
    else
        table.insert(result_t, "") -- an empty line is required to end the headers
    end
    return table.concat(result_t, "\r\n")
end

local function build_response(t)
    require_field(t, 'status')
    t.minor_version = t.minor_version or 1
    if not (t['Content-Length'] and t['Transfer-Encoding']) then
        if t[1] then
            t['Content-Length'] = tostring(#t[1])
        end
    end
    local result_t = {}
    table.insert(result_t, string.format("HTTP/1.%d %s %s", t.minor_version, t.status, response_code2status_table[t.status]))
    for k, v in pairs(t) do
        if (not tonumber(k)) and (not (k == 'status' or k == 'minor_version')) then
            table.insert(result_t, string.format("%s: %s", k, v))
        end
    end
    table.insert(result_t, "")
    if #t > 0 then
        local transfer_encoding = t['Transfer-Encoding']
        if transfer_encoding and string.lower(transfer_encoding) == 'chunked' then
            table.insert(result_t, tostring(#t[1]))
        end
        table.insert(result_t, t[1])
    else
        table.insert(result_t, "") -- an empty line is required to end the headers
    end
    return table.concat(result_t, "\r\n")
end

local headers = {}

function headers:clone_to(new_t)
    utils.table_deep_copy(self, new_t)
end

function headers:add(key, value)
    table.insert(self, {key, value})
end

function headers:search_with_index(key)
    local result = {}
    for i,v in ipairs(self) do
        if v[1] == key then
            table.insert(result, {table.unpack(v), i})
        end
    end
    return result
end

function headers:search(key)
    local result = {}
    for _,v in ipairs(self) do
        if v[1] == key then
            table.insert(result, v)
        end
    end
    return result
end

function headers:remove(index)
    return table.remove(self, index)
end

function headers:get_first_of(key)
    local results = headers.search(self, key)
    if #results > 0 then
        return results[1][2]
    else
        return nil
    end
end

function headers:get_last_of(key)
    local results = headers.search(self, key)
    if #results > 0 then
        return results[#results][2]
    else
        return nil
    end
end

function headers:each()
    local iter = ipairs(self)
    return coroutine.wrap(function()
        local i, v = iter()
        if v then
            coroutine.yield(v[1], v[2], i)
        else
            return nil
        end
    end)
end

function headers:get(key)
    return table.concat(headers.search(self, key), ',')
end

local function wait_for_headers(connection)
    if connection.headers_ready then
        return connection.headers_ready
    end
    local last_len, buffer, httpdata
    while true do
        local data = connection:read()
        local pret
        pret, buffer, last_len, httpdata = lphr.parse_request(data, buffer, last_len)
        if pret > 0 then
            local body_last_in_block = lphr.get_body(buffer, pret)
            connection:putback(body_last_in_block)
            httpdata.uri = pathetic:parse(httpdata.path)
            if not httpdata.headers then
                httpdata.headers = {}
            end
            local header_connection = headers.get_last_of(httpdata.headers, "Connection")
            if (header_connection and string.lower(header_connection) == "keep-alive") then
                connection:set_keep_alive(true)
            elseif httpdata.minor_version == 1 and (string.lower(header_connection or '') ~= "close") then
                connection:set_keep_alive(true)
            end
            return httpdata
        elseif pret == -1 then
            terr.errorT('http', 'request_parsing_error', 'parsing_failed', {
                raw = tostring(buffer)
            })
        end
    end
end

local function read_fixed_body(connection, buffer, length)
    local required_length = length
    required_length = required_length - #(table.concat(buffer)) -- we could not assume the buffer is empty
    while required_length > 0 do
        local data = connection:read()
        required_length = required_length - #data
        table.insert(buffer, data)
    end
end

local function read_chunked_body(connection, buffer)
    local chunk_len_str = table.concat(buffer) -- we cloud not assume the buffer is empty
    local chunk_len
    while not string.match(chunk_len_str, "\r\n") do
        local data = connection:read()
        chunk_len_str = chunk_len_str..data
    end
    local body_prefix
    chunk_len_str, body_prefix = string.match(chunk_len_str, "(.*)\r\n(.*)")
    chunk_len = tonumber(chunk_len_str, 16)
    table.insert(buffer, body_prefix)
    chunk_len = chunk_len - #body_prefix
    while chunk_len > 0 do
        local data = connection:read()
        chunk_len = chunk_len - #data
        table.insert(buffer, data)
    end
    if not string.match(buffer[#buffer], "\r\n") then
        local endmark = connection:read()
        if endmark ~= "\r\n" then
            return -1, "chunk do not end correctly"
        end
    end
end

local function write_error_on(connection, status_code, body)
    connection:write(build_response {
        status = status_code,
        body
    })
end

local function read_body(connection, headers)
    local body_buffer = {}
    local h_content_length = headers.search(headers.headers, "Content-Length")
    local h_transfer_encoding = headers.search(headers.headers, "Transfer-Encoding")
    if #h_content_length > 0 and #h_transfer_encoding >0 then
        write_error_on(connection, 400)
        terr.errorT('http', 'body_read', 'both Content-Length and Transfer-Encoding found', {
            raw = headers
        })
    elseif #h_content_length > 0 then
        local read_length
        local values = utils.exact(h_content_length, 2)
        if not utils.all_equals(values, values[1]) then
            write_error_on(connection, 400)
            terr.errorT('http', 'body_read', "multiple but unequal Content-Length", {
                values = values
            })
        else
            read_length = tonumber(values[1])
            if not read_length then
                write_error_on(connection, 400)
                terr.errorT('http', 'body_read', "Content-Length is NaN", {
                    got_value = tostring(read_length),
                    raw = headers,
                })
            end
        end
        read_fixed_body(connection, body_buffer, read_length)
    elseif #h_transfer_encoding > 0 then
        if string.lower(h_transfer_encoding[#h_transfer_encoding][2]) == "chunked" then
            local stat, e = read_chunked_body(connection, body_buffer)
            if stat then
                write_error_on(connection, 400)
                terr.errorT('http', 'request_read_error', e,{
                    raw = headers
                })
            end
        end
    else
        return nil, headers
    end
    return table.concat(body_buffer), headers
end

local function wait_for_request(connection)
    if connection.request_ready then
        return connection.request_ready
    end
    local httph = wait_for_headers(connection)
    local original_metatable = getmetatable(httph)
    setmetatable(httph, {
        __index = function(t, i)
            if i == 1 then
                t[1] = read_body(connection, httph)
                return t[1]
            else
                local value = rawget(t, i)
                if not value then
                    local index = original_metatable.__index
                    if index then
                        if type(index) == 'table' then
                            return index[i]
                        else
                            return index(i)
                        end
                    end
                end
            end
        end,
    })
    return httph
end

local function respond(connection, response_t)
    connection:write(build_response(response_t))
end

local function respond_on(connection)
    return function(response_t)
        return respond(connection, response_t)
    end
end

local httpconnection = {}

function httpconnection.new()
    return setmetatable({
    }, { __index = httpconnection })
end

function httpconnection.applied(t)
    local obj = httpconnection.new()
    for k,v in pairs(t) do
        obj[k] = v
    end
    return obj
end

function httpconnection:read()
    if self.close_reason then
        terr.errorT('httpconnection', 'closed', self.close_reason)
    end
    if #self > 0 then
        return table.remove(self, 1)
    else
        self.__binded_thread = get_current_thread()
        return self.__read(self.raw)
    end
end

function httpconnection:flush()
    if self.__flush then
        self.__flush(self.raw)
    end
end

function httpconnection:putback(value)
    table.insert(self, value)
end

function httpconnection:write(value)
    if self.close_reason then
        terr.errorT('httpconnection', 'closed', self.close_reason)
    end
    self.__write(self.raw, value)
end

function httpconnection:close(reason)
    self:flush()
    if not self.raw:is_keep_alive() then
        self.raw:close(reason)
    end
    self.close_reason = reason or 'closed'
end

function httpconnection:is_alive()
    return self.close_reason == nil
end

function httpconnection:set_keep_alive(enable)
    self.raw:set_keep_alive(enable)
end

function httpconnection:require_wakeback()
    if not self:is_alive() then
        return false
    else
        return self.__require_wakeback(self.raw)
    end
end

function httpconnection:is_keep_alive()
    return self.raw:is_keep_alive()
end

return {
    request = build_request,
    response = build_response,
    status2code = response_status2code_table,
    code2status = response_code2status_table,
    default_methods = default_methods,
    headers = headers,
    wait_for_headers = wait_for_headers,
    wait_for_request = wait_for_request,
    read_fixed_body = read_fixed_body,
    read_chunked_body = read_chunked_body,
    read_body = read_body,
    respond = respond,
    respond_on = respond_on,
    connection = httpconnection,
}
