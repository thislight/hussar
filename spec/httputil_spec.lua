local mocks = require "away.debugger.mocks"
local lphrc = require "lphr.c"
local Hussar = require "hussar"
local FakeSource = require "hussar.source.fake"
local zlib = require "zlib"
local debugger = require "away.debugger"

describe("httputil", function()
    local httputil = require "hussar.httputil"
    describe("compress_response", function()
        it("correctly compress response when client tells it supports gzip", function()
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
                    ['Accept-Encoding'] = 'gzip',
                }
                local result = conn:read_and_wait()
                local pret, last_len, data
                pret, last_len, data = lphrc.parse_response_r2(result, last_len)
                assert.is.True(pret > 0, "fake_connection must always return the strings as it is")
                assert.equals("gzip", httputil.headers.get_last_of(data.headers, 'Content-Encoding'))
                local body = string.sub(result, pret+1)
                local s = zlib.inflate(15+16)
                local decompressed_body = s(body)
                assert.is.truthy(string.match(decompressed_body, "Test Playload"))
                scheduler:stop()
            end)
            scheduler:run_task(function()
                server:start()
            end)
            scheduler:run()
        end)
        end)

        it("correctly compress response when client tells it supports inflate", function()
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
                    ['Accept-Encoding'] = 'inflate',
                }
                local result = conn:read_and_wait()
                local pret, last_len, data
                pret, last_len, data = lphrc.parse_response_r2(result, last_len)
                assert.is.True(pret > 0, "fake_connection must always return the strings as it is")
                assert.equals("inflate", httputil.headers.get_last_of(data.headers, 'Content-Encoding'))
                local body = string.sub(result, pret+1)
                local s = zlib.inflate()
                local decompressed_body = s(body)
                assert.is.truthy(string.match(decompressed_body, "Test Playload"))
                scheduler:stop()
            end)
            scheduler:run_task(function()
                server:start()
            end)
            scheduler:run()
        end)
        end)

        it("do not compress response when client tells it only supports identity", function()
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
                    ['Accept-Encoding'] = 'identity',
                }
                local result = conn:read_and_wait()
                local pret, last_len, data
                pret, last_len, data = lphrc.parse_response_r2(result, last_len)
                assert.is.True(pret > 0, "fake_connection must always return the strings as it is")
                assert.equals("identity", httputil.headers.get_last_of(data.headers, 'Content-Encoding'))
                local body = string.sub(result, pret+1)
                assert.is.truthy(string.match(body, "Test Playload"))
                scheduler:stop()
            end)
            scheduler:run_task(function()
                server:start()
            end)
            scheduler:run()
        end)
        end)

        it("correctly compress response by gzip when client tells it supports both gzip and identity", function()
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
                    ['Accept-Encoding'] = 'gzip, identity',
                }
                local result = conn:read_and_wait()
                local pret, last_len, data
                pret, last_len, data = lphrc.parse_response_r2(result, last_len)
                assert.is.True(pret > 0, "fake_connection must always return the strings as it is")
                assert.equals("gzip", httputil.headers.get_last_of(data.headers, 'Content-Encoding'))
                local body = string.sub(result, pret+1)
                local s = zlib.inflate(15+16)
                local decompressed_body = s(body)
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