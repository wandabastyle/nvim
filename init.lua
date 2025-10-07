From: <Saved by Blink>
Snapshot-Content-Location: https://sdmntprpolandcentral.oaiusercontent.com/files/00000000-8964-620a-a333-1bdd29db0fc6/raw?se=2025-10-07T21%3A07%3A28Z&sp=r&sv=2024-08-04&sr=b&scid=4c8a926c-6a44-5815-909f-41255f068d4a&skoid=b928fb90-500a-412f-a661-1ece57a7c318&sktid=a48cca56-e6da-484e-a814-9c849652bcb3&skt=2025-10-07T17%3A54%3A08Z&ske=2025-10-08T17%3A54%3A08Z&sks=b&skv=2024-08-04&sig=jMWdETBc4epP0e%2BW/ajdLl4D4TxFUFU/vRm7D8jLOuU%3D
Subject: 
Date: Tue, 7 Oct 2025 23:02:54 +0200
MIME-Version: 1.0
Content-Type: multipart/related;
	type="text/html";
	boundary="----MultipartBoundary--yKs4gWrIFfZdKJ8WIFb1U9KbC5fqh4IolLWxVzQmtS----"


------MultipartBoundary--yKs4gWrIFfZdKJ8WIFb1U9KbC5fqh4IolLWxVzQmtS----
Content-Type: text/html
Content-ID: <frame-0A8E8254C1EEDAC5C4B7765D4BB49D0A@mhtml.blink>
Content-Transfer-Encoding: quoted-printable
Content-Location: https://sdmntprpolandcentral.oaiusercontent.com/files/00000000-8964-620a-a333-1bdd29db0fc6/raw?se=2025-10-07T21%3A07%3A28Z&sp=r&sv=2024-08-04&sr=b&scid=4c8a926c-6a44-5815-909f-41255f068d4a&skoid=b928fb90-500a-412f-a661-1ece57a7c318&sktid=a48cca56-e6da-484e-a814-9c849652bcb3&skt=2025-10-07T17%3A54%3A08Z&ske=2025-10-08T17%3A54%3A08Z&sks=b&skv=2024-08-04&sig=jMWdETBc4epP0e%2BW/ajdLl4D4TxFUFU/vRm7D8jLOuU%3D

<html><head><meta http-equiv=3D"Content-Type" content=3D"text/html; charset=
=3Dwindows-1252"><link rel=3D"stylesheet" type=3D"text/css" href=3D"cid:css=
-f03694f3-9ace-40d2-ad5d-ffdfe7c159dc@mhtml.blink" /><meta name=3D"color-sc=
heme" content=3D"light dark"></head><body><pre style=3D"word-wrap: break-wo=
rd; white-space: pre-wrap;">vim.o.termguicolors =3D true
vim.o.number =3D true
vim.o.relativenumber =3D true
vim.o.swapfile =3D false
vim.o.clipboard =3D "unnamedplus"
vim.o.signcolumn =3D "yes"
vim.o.cursorline =3D true
vim.o.winborder =3D "rounded"

vim.g.mapleader =3D " "

vim.keymap.set('n', '&lt;leader&gt;w', ':write&lt;CR&gt;')
vim.keymap.set('n', '&lt;leader&gt;q', ':quit&lt;CR&gt;')
vim.keymap.set({ 'n', 'v', 'x' }, '&lt;leader&gt;y', '"+y&lt;CR&gt;')
vim.keymap.set({ 'n', 'v', 'x' }, '&lt;leader&gt;d', '"+d&lt;CR&gt;')

vim.keymap.set("n", "&lt;C-Down&gt;", ":m .+1&lt;CR&gt;=3D=3D", { silent =
=3D true, desc =3D "Move line down" })
vim.keymap.set("n", "&lt;C-Up&gt;", ":m .-2&lt;CR&gt;=3D=3D", { silent =3D =
true, desc =3D "Move line up" })


vim.keymap.set("i", "yy", "&lt;Esc&gt;", { noremap =3D true, silent =3D tru=
e, desc =3D "Exit insert mode" })

vim.o.tabstop =3D 2
vim.o.shiftwidth =3D 2
vim.o.softtabstop =3D 2
vim.o.smartindent =3D true
vim.o.autoindent =3D true
vim.o.wrap =3D false

vim.pack.add({
	{ src =3D "https://github.com/folke/tokyonight.nvim" },
	{ src =3D "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src =3D "https://github.com/nvim-lualine/lualine.nvim" },
	{ src =3D "https://github.com/neovim/nvim-lspconfig" },
	{ src =3D "https://github.com/echasnovski/mini.pick" },
	{ src =3D "https://github.com/echasnovski/mini.pairs" },
	{ src =3D "https://github.com/stevearc/oil.nvim" },
})

require "mini.pick".setup()
local pick =3D require("mini.pick").builtin
vim.keymap.set('n', '&lt;leader&gt;ff', pick.files)
vim.keymap.set('n', '&lt;leader&gt;fb', pick.buffers)
vim.keymap.set('n', '&lt;leader&gt;fg', pick.grep)
vim.keymap.set('n', '&lt;leader&gt;h', pick.help)

require "mini.pairs".setup()

require "oil".setup({
	view_options =3D {
		show_hidden =3D true,
	},
})
vim.keymap.set('n', '&lt;leader&gt;e', ":Oil&lt;CR&gt;")

vim.lsp.enable({ "lua_ls" })
vim.keymap.set('n', '&lt;leader&gt;lf', vim.lsp.buf.format)
vim.o.completeopt =3D "menu,menuone,noinsert,noselect"

for k, v in pairs({ ["&lt;Tab&gt;"] =3D { "&lt;C-n&gt;", "&lt;Tab&gt;" }, [=
"&lt;S-Tab&gt;"] =3D { "&lt;C-p&gt;", "&lt;S-Tab&gt;" }, ["&lt;CR&gt;"] =3D=
 { "&lt;C-y&gt;", "&lt;CR&gt;" } }) do
	vim.keymap.set("i", k, function() return vim.fn.pumvisible() =3D=3D 1 and =
v[1] or v[2] end, { expr =3D true, silent =3D true })
end

vim.api.nvim_create_autocmd('LspAttach', {
	callback =3D function(ev)
		local client =3D vim.lsp.get_client_by_id(ev.data.client_id)
		if client:supports_method('textDocument/completion') then
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger =3D tru=
e })
		end
	end,
})
vim.cmd("set completeopt+=3Dnoselect")

vim.cmd("colorscheme tokyonight-moon")

require "lualine".setup()
</pre></body></html>
------MultipartBoundary--yKs4gWrIFfZdKJ8WIFb1U9KbC5fqh4IolLWxVzQmtS----
Content-Type: text/css
Content-Transfer-Encoding: quoted-printable
Content-Location: cid:css-f03694f3-9ace-40d2-ad5d-ffdfe7c159dc@mhtml.blink

@charset "windows-1252";
=0A
------MultipartBoundary--yKs4gWrIFfZdKJ8WIFb1U9KbC5fqh4IolLWxVzQmtS------
