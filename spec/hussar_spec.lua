local away = require "away"
local debugger = require "away.debugger"
local mocks = require "away.debugger.mocks"

describe("hussar", function()
    local Hussar = require "hussar"
    local httputil = require "hussar.httputil"
    local FakeSource = require "hussar.source.fake"

    it("can build a server and play with fake_source correctly", function()
        local handler = mocks.callable(
            function(conn)
                local request = httputil.wait_for_request(conn)
                assert.equals(type(request), "table")
                httputil.respond_on(conn) {
                    status = 200,
                    request.path
                }
            end
        )
        local server = Hussar:create()
        local source = FakeSource:create()
        debugger:new_environment(function(scheduler, debugger)
            debugger:set_timeout(scheduler, 3)
            server:attach_source(source)
            server.handler = handler.mock
            scheduler:run_task(function()
                local conn = source:add_request {
                    method = 'GET',
                    path = '/',
                    ['Transfer-Encoding'] = "Chunked",
                }
                print(conn:read())
            end)
            scheduler:run_task(function()
                server:start()
            end)
            scheduler:run()
        end)
    end)
end)