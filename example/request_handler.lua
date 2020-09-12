local away = require "away"
local Scheduler = away.scheduler
local LuvService = require "away.luv.service"
local hussar = require "hussar"
local LuvSource = require "hussar.source.luv"
local RequestRouter = require "hussar.request_router"

Scheduler:install(LuvService)

local httpserver = hussar:create()

httpserver:attach_source(LuvSource:create("127.0.0.1", 8964))

local router = RequestRouter:create {
    {"/", function(request, response, handle) response.body = "Pls use /hello" end},
    {"/hello", function(request, response, handle) response.body = string.format("Hello %s", request.uri_detail.arguments.name) end}
}

router:attach(httpserver)

Scheduler:run_task(function() httpserver:start() end)

Scheduler:run()
