package = "hussar"
version = "git-0"
source = {
   url = "git+https://github.com/thislight/hussar.git",
}
description = {
   homepage = "https://github.com/thislight/hussar",
   license = "GPL-3",
}
dependencies = {
   "lua >=5.3, <=5.4",
   "away >=0.0.3-1, <1",
   "luapicohttpparser 0.2-0",
   "pathetic >=1.0.2, <2",
   "powerlog 0.1"
}
build = {
   type = "builtin",
   modules = {
      hussar = "src/hussar.lua",
      ['hussar.httputil'] = "src/httputil.lua",
      ['hussar.source.luv'] = "src/source/luv.lua",
      ['hussar.request_router'] = "src/request_router/init.lua",
   }
}
