

--[[
    The default implementation of HTTPConnection provided by hussar.
    In fact you can custom the instance or even create a whole new one for hussar.
    Hussar is always duck-typing.
]]
local record HTTPConnection<T>
    __raw: nil | T
    __read: nil | function(T): any
    __write: nil | function(T, any): nil
    __require_wakeback: nil | function(T): boolean
    __flush: nil | function(T): nil
end

function HTTPConnection.new<T>(): HTTPConnection<T> end

--[[
    This function create a new HTTPConnection and set key-value pairs from parameter `t`.

    The default implementation of HTTPConnection provided by hussar requires a raw connection to work.
    This connection at least can send and recvice strings.
    In this method to create HTTPConnection, the `t` must provide pre-defined actions as hooks to speed up calling:
    * __read
    * __write
    * __require_wakeback
    * __flush (optional)
    And it must provide the actual object to call hooks as field `__raw`.
    The type `T` must contains some methods to make all functions work:
    * :set_keep_alive(boolean)
    * :is_keep_alive()
    These two methods above is for check or keep the connection keep alive (used by default in HTTP/1.1 or enabled by Connection: Keep-Alive header)
    * :close(any)
    Actuaclly close the connection.
]]
function HTTPConnection.applied<T>(t: T): HTTPConnection<T> end

function HTTPConnection:read<V>(): V end

function HTTPConnection:write<V>(value: V): nil end

--[[
    Call __flush hook if it's presented.
]]
function HTTPConnection:flush(): nil end

function HTTPConnection:require_wakeback(): boolean end

function HTTPConnection:putback<V>(value: V): nil end

function HTTPConnection:is_alive(): boolean end

--[[
    Flush buffer and close the HTTP connection.
    It does not mean the raw connection will be close. The connection will be close only when the connection is not keep-alive.
]]
function HTTPConnection:close(reason: any): nil end

function HTTPConnection:is_keep_alive(): boolean end

function HTTPConnection:set_keep_alive(enable: boolean): nil end

--[[
    Build a real HTTP/1.1 and HTTP/1.0 style request from table `t`.

    Two fields are required: `method` and `path`. You could custom the minor version number by `minor_version`, default value is 1.
    All any other key-values will be treat as header. The table of values will be create mutli-value headers. For example:
    ````
    ["Accept"] = {"plain/text", "application/json"}
    ```` 
    will be transformed to:
    ````
    Accept: plain/text
    Accept: application/json
    ````
    So in the case the correct way is:
    ````
    ["Accept"] = "plain/text, application/json"
    ````
    The first element will be the body of the request.

    Full sample:
    ````
    build_request {
        method = "GET",
        path = "/",
        ["User-Agent"] = "HumanPot/14nmpppppppppppppppp",
        ["X-Message-Type"] = {
            "quote",
            "word",
            "english",
            "fake_news",
        },
        "It just works on my machine!"
    }
    ````
]]
local function build_request(t: table): string end

--[[
    Build a real HTTP/1.1 aand HTTP/1.0 style response from table `t`.

    Only field "status" is required. You can custom minor version number by `minor_version`, default is 1.
    The way of key-values treatment is same as `build_request`.
    The first element will be the body of response.
    If Tranfser-Encoding and Content-Length are not presented, a Content-Length will be set by the length of the body if body exists.
    If Tranfer-Encoding is "chunked", a length of body will be inserted just before content as a chunk.
]]
local function build_response(t: table): string end

local response_status2code: {string: number}
local response_code2status: {number: string}
local default_methods: {string}

local type HTTPHeader = {string}

local record headers
    {HTTPHeader}
end

function headers:clone_to(new_t: table): headers end

function headers.new(): headers end

--[[
    Parse mutli-value value which sperated by ','.
]]
function headers.parse_mutliargs(header_or_string: string | HTTPHeader): {string} end

function headers:add(key:string, value:string): nil end

function headers:search_with_index(key: string): {number} end

function headers:search(key: string): {HTTPHeader} end

function headers:remove(index: number): HTTPHeader end

function headers:get_first_of(key: string): string end

function headers:get_last_of(key: string): string end

function headers:get_all_of(key: string): {string} end

function headers:each(key): (function(): string, string, number) end

function headers.insert2response(response: table, key: string, value: string): nil end

function headers:get(key: string): string end

function headers.build_headers<R>(t: {HTTPHeader}, filter: (function(string, string): boolean), mapping: (function(string, string): R)): {R} end

local function wait_for_headers(connection: HTTPConnection): table end

local function read_fixed_body(connection: HTTPConnection, buffer: {any}, length: number): nil end

local function read_chunked_body(connection: HTTPConnection, buffer: {any}): nil end

local function read_body(connection: HTTPConnection, request: table): string end

local function wait_for_request(connection: HTTPConnection): table end

local function respond(connection: HTTPConnection, response: table): nil end

local function respond_on(connection:HTTPConnection): (function(response: table): nil) end

local function compress_response(response: table, request_headers: {HTTPHeader}, compress_avaliables: {string: (function(string): string)}, options: {string: table}): table end

return {
    connection = HTTPConnection,
    build_request = build_request,
    build_response = build_response,
    status2code = response_status2code,
    code2status = response_code2status,
    default_methods = default_methods,
    headers = headers,
    wait_for_headers = wait_for_headers,
    wait_for_request = wait_for_request,
    read_body = read_body,
    read_chunked_body = read_chunked_body,
    read_fixed_body = read_fixed_body,
    respond = respond,
    respond_on = respond_on,
    compress_response = compress_response,
}
