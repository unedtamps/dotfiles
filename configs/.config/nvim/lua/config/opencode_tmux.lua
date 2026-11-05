-- Send editor context to the OpenCode TUI running in a tmux pane.
--
-- OpenCode v2 removed the `/tui/*` API endpoints, so there is no way to append
-- to the prompt of a TUI you are already running through the HTTP API. Instead
-- this types the context into the actual tmux pane via `tmux send-keys`, which
-- targets whatever session/tab that TUI is currently showing.

local M = {}

local function notify(msg, level)
	vim.notify("opencode: " .. msg, level or vim.log.levels.WARN)
end

local function shell(cmd)
	local out = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		return nil
	end
	return out
end

---Session and window of the tmux window Neovim itself is running in.
---@return string? session
---@return string? window
local function current_target()
	local pane = vim.env.TMUX_PANE
	if not pane then
		return nil, nil
	end
	local out = shell({ "tmux", "display-message", "-p", "-t", pane, "#{session_name}\t#{window_id}" })
	if not out then
		return nil, nil
	end
	local session, window = vim.trim(out):match("^([^\t]*)\t([^\t]*)$")
	return session, window
end

---Find the OpenCode TUI pane in the current tmux session (or elsewhere as a
---fallback). Prefers panes in the same session, then the active pane/window.
---@return string? pane_id
---@return string? error
function M.find_pane()
	if not vim.env.TMUX then
		return nil, "not running inside tmux"
	end

	local out = shell({
		"tmux",
		"list-panes",
		"-a",
		"-F",
		"#{pane_id}\t#{pane_current_command}\t#{pane_title}\t#{session_name}\t#{window_index}.#{pane_index}\t#{pane_active}\t#{window_active}\t#{window_id}",
	})
	if not out then
		return nil, "failed to list tmux panes"
	end

	local my_session, my_window = current_target()
	local candidates = {}

	for line in out:gmatch("[^\n]+") do
		local id, cmd, title, session, win, pane_active, window_active, window_id =
			line:match("^(%%%d+)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([01]?)\t([01]?)\t([^\t]*)$")
		if id and (cmd == "opencode" or (title ~= "" and title:match("^OC"))) then
			local score = 0
			if my_session and session == my_session then
				score = score + 100
			end
			if my_window and window_id == my_window then
				score = score + 50
			end
			if pane_active == "1" then
				score = score + 10
			end
			if window_active == "1" then
				score = score + 5
			end
			candidates[#candidates + 1] = { id = id, title = title, session = session, win = win, score = score }
		end
	end

	if #candidates == 0 then
		return nil, "no OpenCode pane found (looked for command `opencode` or title `OC …`)"
	end

	table.sort(candidates, function(a, b)
		return a.score > b.score
	end)
	return candidates[1].id
end

---Send literal text to a tmux pane, without submitting.
---@param pane string
---@param text string
function M.send_text(pane, text)
	local out = shell({ "tmux", "send-keys", "-t", pane, "-l", "--", text })
	if not out and vim.v.shell_error ~= 0 then
		notify("failed to send text to pane " .. pane)
		return false
	end
	return true
end

---Press Enter in a tmux pane.
---@param pane string
function M.send_enter(pane)
	shell({ "tmux", "send-keys", "-t", pane, "Enter" })
end

---Format a buffer location as an OpenCode reference (`path:L10:C1-L20`).
---@param buf integer
---@param from integer[]
---@param to? integer[]
---@param linewise? boolean
---@return string?
local function make_ref(buf, from, to, linewise)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" then
		return nil
	end
	local path = vim.fn.fnamemodify(name, ":.")
	if linewise then
		return string.format("%s:L%d-L%d", path, from[1], to[1])
	end
	if to then
		return string.format("%s:L%d:C%d-L%d:C%d", path, from[1], from[2], to[1], to[2])
	end
	return string.format("%s:L%d:C%d", path, from[1], from[2])
end

---Selection when a mapping fires from visual mode. `'<`/`'>` are not updated
---yet at that point, so read the live selection (`v` mark + cursor) instead.
---@return string?
local function selection_ref()
	local mode = vim.fn.mode()
	if not (mode == "v" or mode == "V" or mode == "\22") then
		return nil
	end

	local a = vim.fn.getpos("v")
	local b = vim.fn.getpos(".")
	if a[2] == 0 and b[2] == 0 then
		return nil
	end

	local from = { a[2], a[3] }
	local to = { b[2], b[3] }
	if from[1] > to[1] or (from[1] == to[1] and from[2] > to[2]) then
		from, to = to, from
	end

	if mode == "V" then
		return make_ref(0, from, to, true)
	end
	if from[1] == to[1] and from[2] == to[2] then
		return nil
	end
	return make_ref(0, from, to)
end

---@return string?
local function this_ref()
	local sel = selection_ref()
	if sel then
		return sel
	end
	local pos = vim.api.nvim_win_get_cursor(0)
	return make_ref(0, { pos[1], pos[2] + 1 })
end

---@return string?
local function file_ref()
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" then
		return nil
	end
	return vim.fn.fnamemodify(name, ":.")
end

---@return string?
local function diagnostics_ref()
	local diags = vim.diagnostic.get(0)
	if #diags == 0 then
		diags = vim.diagnostic.get()
	end
	local refs = {}
	for i, d in ipairs(diags) do
		if i > 10 then
			break
		end
		local ref = make_ref(d.bufnr, { d.lnum + 1, d.col + 1 }, {
			(d.end_lnum or d.lnum) + 1,
			(d.end_col or d.col) + 1,
		})
		if ref then
			refs[#refs + 1] = ref
		end
	end
	return #refs > 0 and table.concat(refs, " ") or nil
end

local handlers = {
	this = this_ref,
	selection = selection_ref,
	file = file_ref,
	buffer = file_ref,
	diagnostics = diagnostics_ref,
}

---Expand `@this`, `@selection`, `@file`, `@buffer` and `@diagnostics`.
---@param text string
---@return string
local function render(text)
	return (text:gsub("@(%a+)", function(name)
		local handler = handlers[name]
		if handler then
			return handler() or ""
		end
		return nil
	end))
end

---Add the current context to the OpenCode prompt without submitting it.
---@param placeholders? string
---@return boolean
function M.append(placeholders)
	-- Capture the context before touching tmux: system calls can move the
	-- cursor and lose a live visual selection.
	local text = render(placeholders or "@this")
	if text == "" then
		notify("nothing to add: empty context")
		return false
	end

	local pane, err = M.find_pane()
	if not pane then
		notify(err)
		return false
	end

	text = text:gsub("%s*\n%s*", " ")
	if not text:match("%s$") then
		text = text .. " "
	end
	return M.send_text(pane, text)
end

---Open a prompt prefilled with the context and submit it to the TUI.
function M.ask()
	local context = render("@this")
	local prefix = context ~= "" and (context .. ": ") or ""

	vim.ui.input({ prompt = "OpenCode: ", default = prefix }, function(input)
		if not input or vim.trim(input) == "" then
			return
		end
		local pane, err = M.find_pane()
		if not pane then
			notify(err)
			return
		end
		if M.send_text(pane, input) then
			M.send_enter(pane)
		end
	end)
end

function M.setup()
	vim.keymap.set({ "n", "x" }, "<C-a>", M.ask, { desc = "Ask OpenCode (tmux)" })
	vim.keymap.set({ "n", "x" }, "go", function()
		M.append("@this")
	end, { desc = "Add context to OpenCode prompt" })
	vim.keymap.set("n", "goo", function()
		M.append("@this")
	end, { desc = "Add line to OpenCode prompt" })
	vim.keymap.set({ "n", "x" }, "<leader>oa", M.ask, { desc = "Ask OpenCode (tmux)" })
	vim.keymap.set({ "n", "x" }, "<leader>oA", function()
		M.append("@this")
	end, { desc = "Add context to OpenCode prompt" })
end

return M
