insulate("hussar.source.fake", function()
    local fake = require "hussar.source.fake"
    it("can be created as a object", function()
        local obj = fake:create()
        assert.is.truthy(obj)
    end)

    describe("add_request()", function()
        it("returns a connection after been called", function()
            local conn = fake:add_request {
                path = '/',
                method = 'GET',
            }
            assert.are.equals(type(conn), 'table')
            assert.is.truthy(conn.read) -- a smoke test
        end)
    end)

    describe("pull()", function()
        it("returns empty table when no new connection", function()
            local obj = fake:create()
            local result = obj:pull()
            assert.are.equals(type(result), 'table')
            assert.are.equals(#result, 0)
        end)

        it("returns new connections after called add_request()", function()
            local obj = fake:create()
            local conn = obj:add_request {
                path = '/',
                method = 'GET'
            }
            local result = obj:pull()
            assert.are.equals(#result, 1)
            assert.are.same(conn, result[1])
        end)
    end)

    insulate("fake_connection", function()
        local httputil = require "hussar.httputil"
        local source = fake:create()
        describe("read()", function()
            it("can return correct infomation", function()
                local conn = source:add_request {
                    path = '/',
                    method = 'GET'
                }
                local result = httputil.wait_for_headers(conn)
                assert.are_not.same(result, -1)
                assert.are.same(result.path, '/')
                assert.are.same(result.method, 'GET')
            end)
        end)
    end)
end)
