

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
    If Tranfer-Encoding is "chunked", a length will be inserted just before content as a chunk.
]]
local function build_response(t: table): string end

local response_status2code: {string: number}
local response_code2status: {number: string}
local default_methods: {string}

return {
    connection = HTTPConnection,
    build_request = build_request,
    build_response = build_response,
    status2code = response_status2code,
    code2status = response_code2status,
    default_methods = default_methods,
}
