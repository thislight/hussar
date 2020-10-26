local away = require "away"
local debugger = require "away.debugger"
local mocks = require "away.debugger.mocks"

describe("hussar", function()
    local Hussar = require "hussar"
    local httputil = require "hussar.httputil"
    local FakeSource = require "hussar.source.fake"
    local wrap_thread = require "hussar.wrap_thread"
    local lphrc = require "lphr.c"

    it("can build a server and play with fake_source correctly", function()
        local handler = mocks.callable(
            wrap_thread(function(conn)
                local request = httputil.wait_for_request(conn)
                assert.equals(type(request), "table")
                httputil.respond_on(conn) {
                    status = 200,
                    request.path
                }
            end)
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
                }
                local result = conn:read_and_wait()
                local pret, last_len, data
                pret, last_len, data = lphrc.parse_response_r2(result, last_len)
                assert.is.True(pret > 0, "fake_connection must always return the strings as it is")
                assert.is.truthy(string.match((string.sub(result, last_len)), "%/$"))
                scheduler:stop()
            end)
            scheduler:run_task(function()
                server:start()
            end)
            scheduler:run()
        end)
    end)
end)