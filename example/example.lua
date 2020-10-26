local away = require "away"
local debugger = require "away.debugger"
local Hussar = require "hussar"
local FakeSource = require "hussar.source.fake"
local httputil = require "hussar.httputil"

local server = Hussar:create()
table.insert(server.logger.receivers, require("powerlog.stdout")())
server.logger.accept_level = 50
local source = FakeSource:create()
local wrap_thread = require "hussar.wrap_thread"

server.handler = wrap_thread(function(conn, frame, pubframe)
    local request = httputil.wait_for_request(conn)
    print("---- Request in Table ----")
    print(debugger.topstring(request))
    print("--------")
    if request.path == '/' and string.lower(request.method) == "post" then
        httputil.respond_on(conn) {
            status = 200,
            string.format("Hello %s!", request[1] or "World")
        }
        conn:close()
    else
        httputil.respond_on(conn) {
            status = 404,
        }
        conn:close()
    end
end)

server:attach_source(source)

away.scheduler:run_task(function()
    local the_name = "The Courier"
    local conn = source:add_request {
        method = 'POST',
        path = '/',
        the_name,
    }
    local s = conn:read_and_wait()
    print("---- Response ----")
    print(s)
    print("--------")
    away.scheduler:stop()
end)

away.scheduler:run_task(function()
    server:start()
end)

away.scheduler:run()
