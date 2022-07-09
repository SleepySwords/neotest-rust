local async = require("neotest.async")
local Path = require 'plenary.path'
local lib = require 'neotest.lib'

require('plenary.filetype').add_file 'rs'


---@class neotest.Adapter
---@field name string
local NeotestAdapter = { name="neotest-rust" }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function NeotestAdapter.root(dir)
  async.api.nvim_command('echo ' .. vim.inspect(lib.files.match_root_pattern("Cargo.lock")(dir)))
  return lib.files.match_root_pattern("Cargo.lock")(dir)
end

---@async
---@param file_path string
---@return boolean
function NeotestAdapter.is_test_file(file_path)
  if not vim.endswith(file_path, '.rs') then
    return false
  end
    return true
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function NeotestAdapter.discover_positions(file_path)
  local query = [[
	(
          (attribute_item (meta_item ((identifier) @attribute)))
	    (#eq? @attribute "test")
          . (function_item
            name: (identifier) @test.name)
            @test.definition
	)
	(mod_item
	  name: (identifier) @namespace.name)
	  @namespace.definition
    ]]
  return lib.treesitter.parse_positions(file_path, query, { require_namespaces = false })
end

---@param args neotest.RunArgs
---@return neotest.RunSpec
function NeotestAdapter.build_spec(args)
  -- Testing(args.tree)
  local position = args.tree:data()
  async.api.nvim_command('echo ' .. vim.inspect(position.id))
  local results_path = async.fn.tempname()
  local command = vim.tbl_flatten({
    "cargo", "test", "--",
    "--logfile",
    results_path,
    vim.list_extend(args.extra_args or {})
  })
end

function Testing(tree)
  local api = async.api
  local buf = async.api.nvim_create_buf(false, true)
  -- get dimensions
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  -- calculate our floating window size
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)

  -- and its starting position
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)
  local opts = {
    style = "minimal",
    relative = "win",
    width = win_width,
    height = win_height,
    row = row,
    col = col
  }
  local lines = {}
  for s in vim.inspect(tree:to_list()):gmatch("[^\r\n]+") do
    table.insert(lines, s)
  end
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  win = async.api.nvim_open_win(buf, true, opts)
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function NeotestAdapter.results(spec, result, tree) end

return NeotestAdapter
