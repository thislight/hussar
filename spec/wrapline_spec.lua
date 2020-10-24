local wrapline = require "hussar.wrapline"

describe("wrapline", function()
    describe("wrap_context()", function()
        it("can pass multiple arguments whatever in wrapping and calling", function()
            local target = function(...)
                assert.equals(4, select("#", ...))
            end
            local wrapped = wrapline.wrap_context(target, 1, 2)
            wrapped(3, 4)
        end)
        it("can pass multiple arguments while wrapping", function()
            local target = function(...) assert.equals(4, select("#", ...)) end
            local wrapped = wrapline.wrap_context(target, 1, 2, 3, 4)
            wrapped()
        end)
        it("wrapped function can be called times and works transparently", function()
            local target = function(...) assert.equals(4, select("#", ...)) end
            local wrapped = wrapline.wrap_context(target, 1, 2)
            wrapped(3, 4)
            wrapped(5, 6)
        end)
    end)
end)
