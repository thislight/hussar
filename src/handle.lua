local utils = require "hussar.utils"

local handle = {}

function handle:apply_to(t)
    utils.table_deep_copy(self, t)
    return t
end
