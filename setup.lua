require("neotest").setup({
	icons = {
		expanded = "",
		-- child_prefix = "",
		-- child_indent = "",
		-- final_child_prefix = "",
		-- non_collapsible = "",
		collapsed = "",

		passed = "",
		running = "",
		failed = "",
		unknown = "",
	},
	adapters = {
		-- require("neotest-python")({
		--     dap = { justMyCode = false },
		-- }),
		require("neotest-rust"),
		require("neotest-vim-test")({
			ignore_file_types = { "rust", "python", "vim", "lua" },
		}),
	},
})
