local autopairs = require("nvim-autopairs")
local lastplace = require("nvim-lastplace")

autopairs.setup({
	check_ts = true,
	enable_check_bracket_line = false,
})

lastplace.setup({
	lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
	lastplace_ignore_filetype = { "gitcommit", "gitrebase" },
	lastplace_open_folds = true,
})

local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
	local cmp_autopairs = require("nvim-autopairs.completion.cmp")
	cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
end
