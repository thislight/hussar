local away = require "away"
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
    if request.path == '/' then
        httputil.respond_on(conn) {
            status = 200,
            "Hello World!"
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
    local conn = source:add_request {
        method = 'GET',
        path = '/',
    }
    local s = conn:read_and_wait()
    print(s)
    away.scheduler:stop()
end)

away.scheduler:run_task(function()
    server:start()
end)

away.scheduler:run()
