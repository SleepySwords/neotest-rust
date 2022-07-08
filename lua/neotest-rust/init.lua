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
NeotestAdapter.root = lib.files.match_root_pattern("Cargo.lock")

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
  local position = args.tree:data()
  if position.type ~= "test" then
    return
  end
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function NeotestAdapter.results(spec, result, tree) end

return NeotestAdapter
