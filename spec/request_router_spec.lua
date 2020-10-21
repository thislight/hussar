describe("hussar.checkers", function()
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
                })
            local result = router:route(fake_request)
            assert.equals(mock_handler1.mock, result)
        end)
    end)
end)
