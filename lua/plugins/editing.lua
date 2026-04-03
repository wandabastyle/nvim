local autopairs = require("nvim-autopairs")

autopairs.setup({
	check_ts = true,
	enable_check_bracket_line = false,
})

local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
	local cmp_autopairs = require("nvim-autopairs.completion.cmp")
	cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
end
