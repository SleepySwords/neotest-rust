# Heavily work in progress

A Rust adapter for the Neotest plugin

Todo
- [ ] Show output when a test has failed
- [ ] Cleanup code 
- [-] Handle files and directories when executing tests (However, it becomes dodgy when running either `mod.rs` or `main.rs`, as it runs all tests in the module/codebase)
- [ ] Adding DAP support (add a strategy)
- [ ] Write a better way to find tests (check if there is a test attribute in the file)
- [ ] This should be a module based tree rather than a file based tree
- [ ] Workspaces are currently broken (grabs the root dir rather than project dir)
