local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local HTTP = require "luci.http"
local DISP = require "luci.dispatcher"
local UTIL = require "luci.util"
local fs = require "luci.openclash"
local uci = require("luci.model.uci").cursor()

m = SimpleForm("openclash",translate(""))
m.description = translate("")
m.reset = false
m.submit = false

m:section(SimpleSection).template  = "openclash/status"

m:append(Template("openclash/config_edit"))
m:append(Template("openclash/config_upload"))

return m