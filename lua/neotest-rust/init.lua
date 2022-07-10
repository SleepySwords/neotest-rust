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

-- Holy shit lua how do you not have an escape string function
local function escape_pattern(text)
    return text:gsub("([^%w])", "%%%1")
end

-- Literally the most sketch thing
local function extract_module(path)
  local root = NeotestAdapter.root(path)
  path = path:gsub('^' .. escape_pattern(root) .. '/src/?', '')
  path = path:gsub('/mod.rs$', '')
  -- should be path seperator but oh well
  path = path:gsub('/', '::')
  path = path:gsub('%.rs$', '')
  if path == 'main' then
      return nil
  end
  return path:gsub('%.rs$', '')
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
  return lib.treesitter.parse_positions(file_path, query, {
    require_namespaces = false,
    position_id = function(position, namespaces)
      return table.concat(
        vim.tbl_flatten({
          extract_module(position.path),
          vim.tbl_map(function(pos)
            return pos.name
          end, namespaces),
          position.name,
        }),
        "::"
      )
    end,
  })
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

---@param args neotest.RunArgs
---@return neotest.RunSpec
function NeotestAdapter.build_spec(args)

  -- TODO: handle files and directories
  local position = args.tree:data()
  local results_path = async.fn.tempname()
  local command = vim.tbl_flatten({
    "cargo", "test", "--",
    "--logfile",
    results_path,
    args.extra_args or {}
  })
  if position then
    if position.type == 'dir' or position.type == 'file' then
      local module = extract_module(position.id)
      table.insert(command, module)
    end
    if position.type == 'namespace' or position.type == 'test' then
      table.insert(command, position.id)
    end
  end
  -- TODO: add DAP support
  return {
    command = command,
    context = {
      results_path = results_path,
    }
  }
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function NeotestAdapter.results(spec, r, tree)
  -- local success, data = pcall(lib.files.read, result.output)
  -- if not success then
  --   return {}
  -- end
  -- TODO: show the error when failed
  local success, data = pcall(lib.files.read, spec.context.results_path)
  if not success then
    data = "{}"
  end
  local results = {}
  local lines = vim.split(data, '\n')
  for _, line in ipairs(lines) do
    if line ~= '' then
      local result = vim.split(line, ' ')
      local status = 'skipped'
      if result[1] == 'ok' then
        status = 'passed'
      elseif result[1] == 'failed' then
        status = 'failed'
	-- should set parents as failed as well
      end
      results[result[2]] = { status = status }
    end
  end
  return results
end

return NeotestAdapter
