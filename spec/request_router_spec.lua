describe("hussar.request_router.checkers", function()
    local away = require "away"
    local debugger = require "away.debugger"
    local RequestRouter = require "hussar.request_router"
    local checkers = require "hussar.request_router.checkers"
    describe("PATH", function()
        it("return true if request's path is match the rule", function()
            local checker = checkers.PATH("/te(.*)", 'lua')
            local fake_request = {path = '/test'}
            assert.is.True(checker(fake_request))
        end)
        it("set capture to frame if reuqest's path is match the rule",
           function()
            local checker = checkers.PATH("/te(.*)", 'lua')
            local fake_request = {path = '/test'}
            local frame = {}
            assert.is.True(checker(fake_request, frame))
            assert.equals(frame.path_match[1], 'st')
        end)
    end)
end)

describe("hussar.request_router", function()
    local away = require "away"
    local debugger = require "away.debugger"
    local RequestRouter = require "hussar.request_router"
    local checkers = require "hussar.request_router.checkers"
    local mocks = require "away.debugger.mocks"
    describe("route()", function()
        it("can return correct handler by request", function()
            local fake_request = {path = "/test"}
            local mock_handler1 = mocks.callable()
            local mock_handler2 = mocks.callable()
            local router = RequestRouter:create(
                               {
                    {'/test$', mock_handler1.mock},
                    {'/amdyes$', mock_handler2.mock}
                }, {})
            local result = router:route(fake_request, {}, {}, {})
            assert.equals(mock_handler1.mock, result)
            assert.is_not.equals(mock_handler2, result)
        end)
        it("return not found handler if handler not found", function()
            local fake_request = {path = "/test"}
            local router = RequestRouter:create()
            router.not_found_error_handler = function(request, conn, frame, pubframe)
                assert.is.truthy(request)
                assert.is.truthy(conn)
                assert.is.truthy(frame)
                assert.is.truthy(pubframe)
                return {
                    status = 404,
                }
            end
            local user_handler = router:route(fake_request, {fake_conn=true}, {fake_frame=true}, {fake_pubframe=true})
            local result = user_handler()
            --[[
                the reason to compare the result of calling but not reference of function is,
                request_router will wrap the not_found_handler to make sure it can receive four arguments (request, conn, frame, pubframe) as promised
            ]]
            assert.is_not.equals(router.not_found_error_handler, user_handler)
            assert.are.same({status = 404}, result)
        end)
    end)
end)

describe("hussar.request_router.method_picker", function()
    local away = require "away"
    local debugger = require "away.debugger"
    local hussar = require "hussar"
    local method_picker = require "hussar.request_router.method_picker"
    local fake_source = require "hussar.source.fake"
    local RequestRouter = require "hussar.request_router"
    local httputil = require "hussar.httputil"
    
    it("can pick correct method depends on request", debugger:wrapenv(function(scheduler, debugger)
        debugger:set_timeout(scheduler, 3)
        local server = hussar:create()
        local source = fake_source:create()
        server:attach_source(source)
        local home_handler = method_picker {
            get = function(request, frame, pubframe)
                return {
                    status = 200,
                    "GET"
                }
            end,
            post = function(request, frame, pubframe)
                return {
                    status = 200,
                    "POST"
                }
            end,
        }
        local router = RequestRouter.new({
            {'/', home_handler}
        })
        server.handler = router:make_handler()

        scheduler:run_task(function()
            local cli_conn = source:add_request{method = 'GET', path = '/'}
            local result0 = cli_conn:read_and_wait()
            assert.is.truthy(string.match(result0, "GET"))
            local cli_conn1 = source:add_request{method = 'POST', path = '/'}
            local result1 = cli_conn1:read_and_wait()
            assert.is.truthy(string.match(result1, "POST"))
            scheduler:stop()
        end)

        scheduler:run()
    end))

    local lphrc = require "lphr.c"

    local function parse_response(s)
        local pret, last_len, data = lphrc.parse_response_r2(s, nil)
        return data, pret
    end

    it("can set correct CORS headers if _CORS set 'all'",
       debugger:wrapenv(function(scheduler, debugger)
        debugger:set_timeout(scheduler, 3)
        local server = hussar:create()
        local source = fake_source:create()
        server:attach_source(source)
        local home_handler = method_picker {
            _CORS = "all",
            post = function(request, frame, pubframe)
                return {status = 200, "POST"}
            end
        }
        local router = RequestRouter.new({{'/', home_handler}})
        server.handler = router:make_handler()

        scheduler:run_task(function() server:start() end)

        scheduler:run_task(function()
            do
                local cli_conn = source:add_request{
                    method = 'OPTIONS',
                    path = '/',
                    Origin = "example.com"
                }
                local result = cli_conn:read_and_wait()
                local response, pret = parse_response(result)
                assert(pret > 0)
                assert.equals("POST,OPTIONS", httputil.headers.get_last_of(
                                  response.headers,
                                  "Access-Control-Allow-Methods"))
                assert.equals("*", httputil.headers.get_last_of(
                                  response.headers,
                                  "Access-Control-Allow-Origin"))
            end
            do
                local cli_conn = source:add_request{
                    method = 'POST',
                    path = '/',
                    Origin = "example.com"
                }
                local result = cli_conn:read_and_wait()
                local response, pret = parse_response(result)
                assert(pret > 0)
                assert.is.truthy(string.match(result, "POST"))
                assert.equals("POST,OPTIONS", httputil.headers.get_last_of(
                                  response.headers,
                                  "Access-Control-Allow-Methods"))
                assert.equals("*", httputil.headers.get_last_of(
                                  response.headers,
                                  "Access-Control-Allow-Origin"))
            end
            scheduler:stop()
        end)

        scheduler:run()
    end))
end)
