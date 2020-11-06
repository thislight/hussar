insulate("hussar.source.fake", function()
    local away = require "away"
    local Debugger = require "away.debugger"
    local mocks = require "away.debugger.mocks"
    local fake = require "hussar.source.fake"
    it("can be created as a object", function()
        local obj = fake:create()
        assert.is.truthy(obj)
    end)

    describe("add_request()", function()
        it("returns two connection after been called", function()
            local source = fake:create()
            local conn, server_conn = source:add_request {
                path = '/',
                method = 'GET',
            }
            assert.are.equals(type(conn), 'table')
            assert.is.truthy(conn.read) -- a smoke test
            assert.is.truthy(server_conn.read) -- a smoke test
        end)
    end)

    describe("fake_connection", function()
        it("can read() and write() correctly", function()
            local source = fake:create()
            local conn, server_conn = source:new_connection()
            conn:write("Hello")
            local r = server_conn:read()
            assert.equals(r, "Hello")
        end)

        it("can read() and write() times correctly", function()
            Debugger:new_environment(function(scheduler, debugger)
                debugger:set_timeout(scheduler, 10)
                local source = fake:create()
                local conn, server_conn = source:new_connection()
                scheduler:run_task(function()
                    conn:write("Hello1")
                    away.wakeback_later()
                    conn:write("Hello2")
                    away.wakeback_later()
                    conn:write("Hello3")
                end)
                local reach = false
                scheduler:run_task(function()
                    assert.equals(server_conn:read_and_wait(), "Hello1")
                    assert.equals(server_conn:read_and_wait(), "Hello2")
                    assert.equals(server_conn:read_and_wait(), "Hello3")
                    reach = true
                end)
                scheduler:run()
                assert.is.True(reach, "all message must be received")
            end)
        end)

        it("is_alive() can check whether died or alive, close() can close connection", function()
            local source = fake:create()
            local conn, server_conn = source:new_connection()
            assert.is.True(conn:is_alive())
            server_conn:close()
            assert.is.False(conn:is_alive())
        end)

        it("set_keep_alive() can set if connection can keep alive, is_keep_alive() can check if connection is keeping alive", function()
            local source = fake:create()
            local conn, server_conn = source:new_connection()
            assert.is.False(conn:is_keep_alive())
            server_conn:set_keep_alive(true)
            assert.is.True(conn:is_keep_alive())
        end)
    end)

    describe("fake_source", function()
        local debugger = require "away.debugger"

        it("call hussar's add_http_connection when new connection appeared", function()
            local source = fake:create()
            local add_http_connection = mocks.callable()
            local fake_hussar = {
                add_http_connection = add_http_connection.mock,
                logger = source.logger,
            }
            source:prepare(fake_hussar)
            source:new_connection()
            assert.equals(add_http_connection.called_count, 1)
        end)

        it(
            "can reuse same connection with two requests for Connection: keep-alive (default in HTTP/1.1)",
            debugger:wrapenv(function(scheduler, debugger)
                debugger:set_timeout(scheduler, 2)
                local hussar = require "hussar"
                local httputil = require "hussar.httputil"
                local source = fake:create()
                local server = hussar:create()
                server.pubframe.debug = true
                server.handler = function(conn, frame, pubframe)
                    local headers = httputil.wait_for_headers(conn)
                    httputil.respond_on(conn) {
                        status = 200,
                        "Test"
                    }
                    conn:close()
                end
                server:attach_source(source)
                scheduler:run_task(function()
                    server:start()
                end)
                local reach = false
                scheduler:run_task(function()
                    local connection, server_side = source:new_connection()
                    connection:write(httputil.request {
                        method = 'GET',
                        path = '/',
                    })
                    local result = connection:read_and_wait()
                    assert.is.truthy(string.match(result, ".*Test.*"))
                    connection:write(httputil.request {
                        method = 'GET',
                        path = '/',
                    })
                    assert.is.truthy(string.match(connection:read_and_wait(), ".*Test.*"))
                    reach = true
                    scheduler:stop()
                end)
                scheduler:run()
                assert.is.True(reach)
        end))
    end)
end)
