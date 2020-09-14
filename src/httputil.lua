local utils = require "hussar.utils"
local lphr = require "lphr.r2"

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
    t.headers = t.headers or {}
    local result_t = {}
    table.insert(result_t, string.format("%s %s HTTP/1.%d", string.upper(t.method), t.path, t.minor_version))
    for i, v in ipairs(t.headers) do
        table.insert(result_t, string.format("%s: %s", result_t[1], result_t[2]))
    end
    table.insert(result_t, "")
    if t.body ~= nil then
        table.insert(result_t, t.body)
    end
    return table.concat(result_t, "\r\n")
end

local function build_response(t)
    require_field(t, 'status_code')
    t.minor_version = t.minor_version or 1
    t.headers = t.headers or {}
    local result_t = {}
    table.insert(result_t, string.format("HTTP/1.%d %s %s", t.minor_version, t.status, t.code))
    for i, v in ipairs(t.headers) do
        table.insert(result_t, string.format("%s: %s", result_t[1], result_t[2]))
    end
    table.insert(result_t, "")
    if #t > 0 then
        table.insert(result_t, t[0]) -- TODO(thislight): table array as chunked data.
        table.insert(result_t, "")
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
    local results = self:search(key)
    if #results > 0 then
        return results[0]
    else
        return nil
    end
end

function headers:get_last_of(key)
    local results = self:search(key)
    if #results > 0 then
        return results[#results]
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
    return table.concat(self:search(key), ',')
end

local function wait_for_headers(connection)
    local last_len, buffer, httpdata
    while true do
        local data = connection:read()
        local pret
        pret, buffer, last_len, httpdata = lphr.parse_request(data, buffer, last_len)
        if pret > 0 then
            local body_last_in_block = lphr.get_body(buffer, pret)
            if not httpdata.headers then
                httpdata.headers = {}
            end
            return httpdata, body_last_in_block
        elseif pret == -1 then
            return -1
        end
    end
end

local function read_fixed_body(connection, buffer, length)
    local required_length = length
    while required_length > 0 do
        local data = connection:read()
        required_length = required_length - #data
        table.insert(buffer, data)
    end
end

local function read_chunked_body(connection, buffer)
    local chunk_len_str = ""
    local chunk_len
    while not string.match(chunk_len_str, "\r\n") do
        local data = connection:read()
        chunk_len_str = chunk_len_str..data
    end
    local chunk_len_str, body_prefix = string.match(chunk_len_str, "(.*)\r\n(.*)")
    chunk_len = tonumber(chunk_len_str, 16)
    table.insert(buffer, body_prefix)
    chunk_len = chunk_len - #body_prefix
    while chunk_len > 0 do
        local data = connection:read()
        chunk_len = chunk_len - #data
        table.insert(buffer, data)
    end
end

local function write_error_on(connection, status_code, body)
    connection:write(build_response {
        status_code = status_code,
        body
    })
end

local function wait_for_request(connection)
    local httph, body_last_in_block = wait_for_headers(connection)
    if httph == -1 then
        return -1, "headers error"
    end
    local body_buffer = {}
    table.insert(body_buffer, body_last_in_block)
    local h_content_length = headers.search(httph.headers, "Content-Length")
    local h_transfer_encoding = headers.search(httph.headers, "Transfer-Encoding")
    if #h_content_length > 0 and #h_transfer_encoding >0 then
        write_error_on(connection, 400)
        return -1, "both content-length and transfer-encoding recviced"
    elseif #h_content_length > 0 then
        local read_length
        if utils.any(utils.map(function(v) return v ~= h_content_length end, h_content_length)) then
            write_error_on(connection, 400)
            return -1, "multiple but unequal content-length "
        else
            read_length = tonumber(h_content_length[0])
            if not read_length then
                write_error_on(connection, 400)
                return -1, "content-length NaN"
            end
        end
        read_fixed_body(connection, body_buffer, read_length)
    elseif #h_transfer_encoding > 0 then
        if string.lower(h_transfer_encoding[#h_transfer_encoding]) == "chunked" then
            read_chunked_body(connection, body_buffer)
        end
    else
    end
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
}
