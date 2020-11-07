local mocks = require "away.debugger.mocks"
local lphrc = require "lphr.c"
local Hussar = require "hussar"
local FakeSource = require "hussar.source.fake"
local br = require "brotli"
local debugger = require "away.debugger"

describe("httputil", function()
    local httputil = require "hussar.httputil"
    describe("compress_response", function()
        it("correctly compress response when client tells it supports br", function()
            local handler = mocks.callable(
            function(conn)
                local request = httputil.wait_for_headers(conn)
                assert.equals(type(request), "table")
                httputil.respond(conn, httputil.compress_response({
                    status = 200,
                    "Test Playload"
                }, request.headers))
            end
        )
        local server = Hussar:create()
        local source = FakeSource:create()
        debugger:new_environment(function(scheduler, debugger)
            debugger:set_timeout(scheduler, 3)
            server:attach_source(source)
            server.handler = handler.mock
            server.pubframe.debug = true
            scheduler:run_task(function()
                local conn = source:add_request {
                    method = 'GET',
                    path = '/',
                    ['Accept-Encoding'] = 'br',
                }
                local result = conn:read_and_wait()
                local pret, last_len, data
                pret, last_len, data = lphrc.parse_response_r2(result, last_len)
                assert.is.True(pret > 0, "fake_connection must always return the strings as it is")
                assert.equals("br", httputil.headers.get_last_of(data.headers, 'Content-Encoding'))
                local body = string.sub(result, pret+1)
                local decompressed_body = br.decompress(body)
                assert.is.truthy(string.match(decompressed_body, "Test Playload"))
                scheduler:stop()
            end)
            scheduler:run_task(function()
                server:start()
            end)
            scheduler:run()
        end)
        end)
    end)
end)