-- :Check [tsc] [lint] [fmt]  -- the project's checks, in parallel, into one quickfix list.
--
--   tsc   the whole program, through the package.json `tsc` script when there is one (i360: `tsc -b`,
--         incremental, the same command CI and the pre-commit hook run).
--   lint  oxlint (config, jsPlugins, type-aware rules: all from the project).
--   fmt   prettier --list-different, on the file types the pre-commit hook formats.
--
-- :Check   tsc + lint + fmt; lint/fmt on the files changed since the merge-base with origin
--          (+ untracked): what the pre-commit hook will see.
-- :Check!  tsc + lint on the whole repo: what CI runs. Whole-repo prettier only on request
--          (`:Check! fmt`): ~30 s, and it lists files nobody formats (pnpm-lock.yaml, harness YAML).
--
-- The LSP servers (lua/lazzy/lsp.lua) already cover open buffers; this is for everything else.
-- Every tool comes from the project's node_modules/.bin, like the servers.

local M = {}

local lockfiles = { "pnpm-lock.yaml", "package-lock.json", "yarn.lock", "bun.lock", "bun.lockb" }
local lintable = { ts = true, tsx = true, mts = true, cts = true, js = true, jsx = true, mjs = true, cjs = true }
-- i360's utils/config/.lintstagedrc.js: *.{ts,tsx} and *.{js,jsx,json,mjs,less,css,html}
local formattable =
	{ ts = true, tsx = true, js = true, jsx = true, json = true, mjs = true, less = true, css = true, html = true }

---@param root string
---@param name string
local function bin(root, name)
	local path = vim.fs.joinpath(root, "node_modules/.bin", name)
	return vim.fn.executable(path) == 1 and path or nil
end

---@param root string
---@param path string
local function abs(root, path)
	return path:sub(1, 1) == "/" and path or vim.fs.joinpath(root, path)
end

---@param root string
---@return string[]? files changed since the merge-base with origin's default branch, plus untracked ones
local function changed_files(root)
	local function git(args)
		local out = vim.system(vim.list_extend({ "git", "-C", root }, args), { text = true }):wait()
		return out.code == 0 and vim.split(vim.trim(out.stdout), "\n", { trimempty = true }) or nil
	end
	local base
	for _, ref in ipairs({ "origin/HEAD", "origin/master", "origin/main" }) do
		base = (git({ "merge-base", "HEAD", ref }) or {})[1]
		if base then
			break
		end
	end
	if not base then
		return nil
	end
	local files = git({ "diff", "--name-only", "--diff-filter=d", base }) or {}
	vim.list_extend(files, git({ "ls-files", "--others", "--exclude-standard" }) or {})
	return files
end

---@param files string[]
---@param pred fun(ext: string): boolean
local function filter_ext(files, pred)
	return vim.tbl_filter(function(f)
		return pred(f:match("%.([%w]+)$") or "")
	end, files)
end

-- Output parsers: (root, stdout lines, stderr lines) -> quickfix items.

local function parse_tsc(root, lines)
	local items = {}
	for _, line in ipairs(lines) do
		local file, lnum, col, kind, code, msg = line:match("^(.-)%((%d+),(%d+)%): (%a+) (TS%d+): (.*)$")
		if file then
			items[#items + 1] = {
				filename = abs(root, file),
				lnum = tonumber(lnum),
				col = tonumber(col),
				type = kind == "error" and "E" or "W",
				text = ("%s [tsc %s]"):format(msg, code),
			}
		elseif line:match("^%s+%S") and #items > 0 then
			-- continuation of a multi-line message (e.g. "Type X is not assignable ... / Property y ...")
			items[#items].text = items[#items].text .. " | " .. vim.trim(line)
		elseif line:match("error TS%d+") then
			items[#items + 1] = { filename = "", text = line, type = "E" }
		end
	end
	return items
end

local function parse_oxlint(root, lines)
	local items = {}
	for _, line in ipairs(lines) do
		local file, lnum, col, msg, sev, rule = line:match("^(.-):(%d+):(%d+): (.*) %[(%a+)/(.-)%]$")
		if file then
			items[#items + 1] = {
				filename = abs(root, file),
				lnum = tonumber(lnum),
				col = tonumber(col),
				type = sev == "Error" and "E" or "W",
				text = ("%s [%s]"):format(msg, rule),
			}
		end
	end
	return items
end

local function parse_prettier(root, lines, errlines)
	local items = {}
	for _, line in ipairs(lines) do
		if line ~= "" then
			items[#items + 1] = { filename = abs(root, line), lnum = 1, type = "W", text = "not formatted [prettier]" }
		end
	end
	for _, line in ipairs(errlines) do
		if line:match("^%[error%]") then
			items[#items + 1] = { filename = "", text = line, type = "E" }
		end
	end
	return items
end

---@class checks.Job
---@field name string
---@field cmd string[]
---@field env? table<string,string>
---@field parse fun(root: string, out: string[], err: string[]): table[]

---@param root string
---@param full boolean whole repo instead of the changed files
---@param which table<string, boolean>
---@return checks.Job[] jobs, string[] skipped
local function plan(root, full, which)
	local jobs, skipped = {}, {}
	local changed = not full and changed_files(root) or nil

	if which.tsc then
		local pkg = vim.fs.joinpath(root, "package.json")
		local ok, json = pcall(vim.json.decode, table.concat(vim.fn.readfile(pkg), "\n"))
		local has_script = ok and type(json) == "table" and json.scripts and json.scripts.tsc
		local pm = vim.uv.fs_stat(vim.fs.joinpath(root, "pnpm-lock.yaml")) and "pnpm" or "npm"
		if has_script then
			local cmd = { pm, "run", "--silent", "tsc" }
			vim.list_extend(cmd, pm == "npm" and { "--", "--pretty", "false" } or { "--pretty", "false" })
			jobs[#jobs + 1] = { name = "tsc", cmd = cmd, parse = parse_tsc }
		elseif bin(root, "tsc") then
			jobs[#jobs + 1] =
				{ name = "tsc", cmd = { bin(root, "tsc"), "--noEmit", "--pretty", "false" }, parse = parse_tsc }
		else
			skipped[#skipped + 1] = "tsc (no node_modules/.bin/tsc)"
		end
	end

	if which.lint then
		local oxlint = bin(root, "oxlint")
		if not oxlint then
			skipped[#skipped + 1] = "lint (no node_modules/.bin/oxlint)"
		else
			local files = changed and filter_ext(changed, function(ext)
				return lintable[ext]
			end)
			if files and #files == 0 then
				skipped[#skipped + 1] = "lint (no changed JS/TS files)"
			else
				-- unmatched = files the config ignores (outside packages' src/), as in the pre-commit hook
				local cmd = { oxlint, "--format=unix", "--no-error-on-unmatched-pattern" }
				jobs[#jobs + 1] = { name = "lint", cmd = vim.list_extend(cmd, files or {}), parse = parse_oxlint }
			end
		end
	end

	if which.fmt then
		local prettier = bin(root, "prettier")
		if not prettier then
			skipped[#skipped + 1] = "fmt (no node_modules/.bin/prettier)"
		else
			local files = changed and filter_ext(changed, function(ext)
				return formattable[ext]
			end)
			if files and #files == 0 then
				skipped[#skipped + 1] = "fmt (no changed files to format)"
			else
				local cmd = { prettier, "--list-different", "--ignore-unknown" }
				jobs[#jobs + 1] = { name = "fmt", cmd = vim.list_extend(cmd, files or { "." }), parse = parse_prettier }
			end
		end
	end

	return jobs, skipped
end

local running = false

---@param opts { full?: boolean, which?: string[], root?: string }
function M.run(opts)
	opts = opts or {}
	if running then
		vim.notify("Check: already running", vim.log.levels.WARN)
		return
	end
	local root = opts.root or vim.fs.root(0, lockfiles) or vim.fs.root(0, ".git")
	if not root then
		vim.notify("Check: no project root (lockfile or .git) above this buffer", vim.log.levels.WARN)
		return
	end

	local which = {}
	local default = opts.full and { "tsc", "lint" } or { "tsc", "lint", "fmt" }
	for _, w in ipairs(opts.which and #opts.which > 0 and opts.which or default) do
		which[w] = true
	end
	local jobs, skipped = plan(root, opts.full or false, which)
	if #jobs == 0 then
		vim.notify("Check: nothing to run; skipped " .. table.concat(skipped, ", "), vim.log.levels.WARN)
		return
	end

	running = true
	local scope = opts.full and "whole repo" or "changed files"
	vim.notify(("Check (%s): %s …"):format(
		scope,
		table.concat(
			vim.tbl_map(function(j)
				return j.name
			end, jobs),
			", "
		)
	))

	local results, pending = {}, #jobs
	for i, job in ipairs(jobs) do
		local started = vim.uv.hrtime()
		vim.system(job.cmd, { cwd = root, text = true, env = job.env }, function(out)
			vim.schedule(function()
				local stdout = vim.split(out.stdout or "", "\n", { trimempty = true })
				local stderr = vim.split(out.stderr or "", "\n", { trimempty = true })
				local items = job.parse(root, stdout, stderr)
				if #items == 0 and out.code ~= 0 then
					-- failed without anything parseable: show the raw output instead of a false "clean"
					items = vim.tbl_map(function(l)
						return { filename = "", text = ("[%s] %s"):format(job.name, l), type = "E" }
					end, #stderr > 0 and stderr or stdout)
					if #items == 0 then
						items = { { filename = "", text = ("[%s] exited %d"):format(job.name, out.code), type = "E" } }
					end
				end
				results[i] = { name = job.name, items = items, secs = (vim.uv.hrtime() - started) / 1e9 }
				pending = pending - 1
				if pending == 0 then
					running = false
					M.report(root, scope, results, skipped)
				end
			end)
		end)
	end
end

function M.report(root, scope, results, skipped)
	local items, summary, worst = {}, {}, vim.log.levels.INFO
	for _, r in ipairs(results) do
		vim.list_extend(items, r.items)
		local errors = #vim.tbl_filter(function(it)
			return it.type == "E"
		end, r.items)
		local warnings = #r.items - errors
		if errors > 0 then
			worst = vim.log.levels.ERROR
		elseif warnings > 0 and worst < vim.log.levels.WARN then
			worst = vim.log.levels.WARN
		end
		local status = (#r.items == 0) and "ok"
			or (errors > 0 and ("%dE"):format(errors) or "") .. (warnings > 0 and (" %dW"):format(warnings) or "")
		summary[#summary + 1] = ("%s %s (%.1fs)"):format(r.name, vim.trim(status), r.secs)
	end
	if #skipped > 0 then
		summary[#summary + 1] = "skipped: " .. table.concat(skipped, ", ")
	end

	local title = ("Check (%s) %s"):format(scope, vim.fn.fnamemodify(root, ":~"))
	vim.fn.setqflist({}, " ", { title = title, items = items })
	vim.notify(title .. "\n" .. table.concat(summary, "\n"), worst)
	if #items > 0 then
		local ok = pcall(vim.cmd, "Trouble qflist open")
		if not ok then
			vim.cmd("copen")
		end
	end
end

--- Oxlint's safe fixes on one file, as the pre-commit hook applies them: I360_OXLINT_SAFE_FIX=1 keeps
--- out the one autofix i360 considers unsafe (see oxlint.config.mts). The LSP's own fix-all code
--- action (`ga` → "fix all") does not set it.
---@param buf integer
function M.oxlint_fix(buf)
	local file = vim.api.nvim_buf_get_name(buf)
	local root = vim.fs.root(buf, lockfiles)
	local oxlint = root and bin(root, "oxlint")
	if not oxlint then
		vim.notify("oxlint: no node_modules/.bin/oxlint above " .. file, vim.log.levels.WARN)
		return
	end
	if vim.bo[buf].modified then
		vim.api.nvim_buf_call(buf, function()
			vim.cmd("silent write")
		end)
	end
	vim.system(
		{ oxlint, "--fix", "--no-error-on-unmatched-pattern", file },
		{ cwd = root, text = true, env = { I360_OXLINT_SAFE_FIX = "1" } },
		function()
			vim.schedule(function()
				vim.cmd.checktime(buf)
			end)
		end
	)
end

function M.setup()
	vim.api.nvim_create_user_command("Check", function(cmd)
		M.run({ full = cmd.bang, which = cmd.fargs })
	end, {
		bang = true,
		nargs = "*",
		complete = function()
			return { "tsc", "lint", "fmt" }
		end,
		desc = "Project checks (tsc, oxlint, prettier) into quickfix; ! = whole repo, as CI",
	})
	vim.keymap.set("n", "<leader>ck", "<cmd>Check<CR>", { desc = "Check changed files (tsc, lint, fmt)" })
	vim.keymap.set("n", "<leader>cK", "<cmd>Check!<CR>", { desc = "Check whole repo, as CI (tsc, lint)" })
end

return M
