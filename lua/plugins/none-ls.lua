return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        "nvimtools/none-ls-extras.nvim",
        "jayp0521/mason-null-ls.nvim",
    },
    config = function()
	local null_ls = require("null-ls")
	local formatting = null_ls.builtins.formatting
	local diagnostics = null_ls.builtins.diagnostics

	-- Formatters & linters for mason to install
	require("mason-null-ls").setup({
		ensure_installed = {
			"prettier",
			"stylua",
			"eslint_d",
			"shfmt",
			"ruff",
		},
		automatic_installation = true,
	})

	local sources = {
		formatting.prettier.with({ filetypes = { "html", "json", "yaml", "markdown" } }),
		formatting.stylua,
		formatting.shfmt.with({ args = { "-i", "4" } }),
		formatting.terraform_fmt,
		require("none-ls.formatting.ruff").with({ extra_args = { "--extend-select", "I" } }),
		require("none-ls.formatting.ruff_format"),
	}

	-- Function to handle range formatting
	local function format_range()
		local start_line, start_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
		local end_line, end_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))
		-- Adjust for Lua's 1-based indexing
		start_line = start_line - 1
		end_line = end_line - 1
		vim.lsp.buf.format({
			start = { start_line, start_col },
			["end"] = { end_line, end_col },
		})
	end

	null_ls.setup({
		debug = true, -- Enable debug mode. Inspect logs with :NullLsLog.
		sources = sources,
		on_attach = function(client, bufnr)
			if client.supports_method("textDocument/formatting") then
				vim.keymap.set("v", "<leader>f", format_range, {
					buffer = bufnr,
					desc = "Format range",
					noremap = true,
					silent = true,
				})
			end

			-- Optional: Add a keymap for full document formatting
			if client.supports_method("textDocument/formatting") then
				vim.keymap.set("n", "<leader>F", function()
					vim.lsp.buf.format({ bufnr = bufnr })
				end, {
					buffer = bufnr,
					desc = "Format document",
					noremap = true,
					silent = true,
				})
			end
		end,
	})

        -- Command to view null-ls logs
        vim.api.nvim_create_user_command("NullLsLog", function()
            vim.cmd("edit " .. null_ls.get_log_file_path())
        end, {})
    end,
}
