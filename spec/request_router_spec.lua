local away = require "away"
local debugger = require "away.debugger"
local RequestRouter = require "hussar.request_router"
local checkers = require "hussar.request_router.checkers"

describe("hussar.checkers", function()
    describe("PATH", function()
        it("return true if request's path is match the rule", function()
            local checker = checkers.PATH("/te(.*)", 'lua')
            local fake_request = {
                path = '/test'
            }
            assert.is.True(checker(fake_request))
        end)
        it("set capture to frame if reuqest's path is match the rule", function()
            local checker = checkers.PATH("/te(.*)", 'lua')
            local fake_request = {
                path = '/test'
            }
            local frame = {}
            assert.is.True(checker(fake_request, frame))
            assert.equals(frame.path_match[1], 'st')
        end)
    end)
end)
