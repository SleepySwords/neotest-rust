local q = require "vim.treesitter.query"
local async = require("neotest.async")
local lib = require 'neotest.lib'


function i(value)
	print(vim.inspect(value))
end

local bufnr = 8

-- local language_tree = vim.treesitter.get_parser(bufnr, 'rust')
-- local syntax_tree = language_tree:parse()
-- local root = syntax_tree[1]:root()
-- ((
--     (attribute_item) @attribute
--     ((function_item
--       name: (identifier) @test.name))
-- ))

local query = [[
	(
          ((attribute_item) @attribute
	  (#match? @attribute "test")
        )
        . (function_item
          name: (identifier) @test.name)
          @test.definition
	)
	(mod_item
	  name: (identifier) @namespace.name)
	  @namespace.definition
]]

local test_file = [[
#[cfg(test)]
mod tests {
    use crossterm::event::KeyCode;

    use crate::{
        app::{App, TaskData},
        input,
        task::Task,
    };

    #[tesaenkajnt]
    fn test_add_task() {
        let mut app = App::new(crate::theme::Theme::default(), TaskData::default());
        input::handle_input(KeyCode::Char('a'), &mut app);
        input::handle_input(KeyCode::Char('p'), &mut app);
        input::handle_input(KeyCode::Char('p'), &mut app);
        input::handle_input(KeyCode::Char('y'), &mut app);
        input::handle_input(KeyCode::Char('q'), &mut app);
        input::handle_input(KeyCode::Enter, &mut app);
        assert_eq!(app.task_data.tasks[0].title, "ppy")
    }

    #[test]
    fn test_edit_task() {
        let mut app = App::new(
            crate::theme::Theme::default(),
            TaskData {
                tasks: vec![Task::from_string(String::from("meme"))],
                completed_tasks: vec![],
            },
        );
        input::handle_input(KeyCode::Char('e'), &mut app);
        input::handle_input(KeyCode::Char('r'), &mut app);
        input::handle_input(KeyCode::Char('q'), &mut app);
        input::handle_input(KeyCode::Enter, &mut app);
        assert_eq!(app.task_data.tasks[0].title, "memerq")
    }

    fn test_delete_task() {
        let mut app = App::new(
            crate::theme::Theme::default(),
            TaskData {
                tasks: vec![Task::from_string(String::from("meme"))],
                completed_tasks: vec![],
            },
        );
        input::handle_input(KeyCode::Char('d'), &mut app);
        input::handle_input(KeyCode::Enter, &mut app);
        assert_eq!(app.task_data.tasks.len(), 0)
    }

    fn test_cancel_delete_task() {
        let mut app = App::new(
            crate::theme::Theme::default(),
            TaskData {
                tasks: vec![Task::from_string(String::from("meme"))],
                completed_tasks: vec![],
            },
        );
        input::handle_input(KeyCode::Char('d'), &mut app);
        input::handle_input(KeyCode::Char('j'), &mut app);
        input::handle_input(KeyCode::Enter, &mut app);
        assert_eq!(app.task_data.tasks.len(), 1)
    }

    fn ok_zoomer() {
        let mut app = App::new(
            crate::theme::Theme::default(),
            TaskData {
                tasks: vec![Task::from_string(String::from("meme"))],
                completed_tasks: vec![],
            },
        );
        input::handle_input(KeyCode::Char('d'), &mut app);
        input::handle_input(KeyCode::Char('j'), &mut app);
        input::handle_input(KeyCode::Enter, &mut app);
        assert_eq!(app.task_data.tasks.len(), 1)
    }
}
mod ok {
    #[test]
    fn ok_zoomer() {
        let mut app = App::new(
            crate::theme::Theme::default(),
            TaskData {
                tasks: vec![Task::from_string(String::from("meme"))],
                completed_tasks: vec![],
            },
        );
        input::handle_input(KeyCode::Char('d'), &mut app);
        input::handle_input(KeyCode::Char('j'), &mut app);
        input::handle_input(KeyCode::Enter, &mut app);
        assert_eq!(app.task_data.tasks.len(), 1)
    }

}
]]
async.run(function()
	local api = async.api
	local tree = lib.treesitter.parse_positions_from_string('test_file.rs', test_file, query, { nested_namespaces = true })
	i(tree:to_list())
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

	-- set some options
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
end)
