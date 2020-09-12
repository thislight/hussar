local away = require "away"
local Scheduler = away.scheduler
local LuvService = require "away.luv.service"
local hussar = require "hussar"
local LuvSource = require "hussar.source.luv"
local httputil = require "hussar.httputil"

Scheduler:install(LuvService)

local httpserver = hussar:create()

httpserver:attach_source(LuvSource:create("127.0.0.1", 8964))

httpserver.handler = function(connection, frame, pubframe)
    local request = httputil.wait_for_request(connection)
    if request.uri.path == "/" then
        httputil.respond_with(connection, {
            status_code = 200,
            "Hello World!"
        })
    end
    connection:close()
end

Scheduler:run_task(function() httpserver:start() end)

Scheduler:run()
