local notify = require("code_runner.hooks.notify")

local M = {}

local job = nil

function M.preview_open(file, command)
  if job ~= nil then
    -- Viewer already open: it reloads the pdf on change, warning on every
    -- recompile would just be noise.
    return
  end
  job = vim.system({ command, file }, {}, function(obj)
    job = nil
  end)
end

function M.preview_close()
  if job ~= nil then
    job:kill(15)
    job = nil
  end
end

function M.create_stop_hot_reload(id)
  vim.api.nvim_create_user_command("CrStopHr", function(opts)
    require("code_runner.hooks.autocmd").stop(id)
  end, { desc = "Stop hot reload for code runner", nargs = 0 })
end

--- Creates a self-contained job runner with start/stop logic.
--- Supports multiple simultaneous buffers — each buffer gets its own job.
--- @param opts? { on_start?: fun(), on_exit?: fun(), label?: string, stop_command?: string }
--- @return { start: fun(cmd: string|string[]), stop: fun(), stop_all: fun() }
function M.create_job_runner(opts)
  opts = opts or {}
  local label = opts.label or "Job"

  -- State keyed by bufnr: { job_id, autocmd_id }
  local buffers = {}

  local function stop(bufnr)
    local s = buffers[bufnr]
    if not s then
      return
    end

    if s.job_id then
      vim.fn.jobstop(s.job_id)
    end
    if s.autocmd_id then
      vim.api.nvim_del_autocmd(s.autocmd_id)
    end
    buffers[bufnr] = nil
  end

  local function stop_current()
    stop(vim.api.nvim_get_current_buf())
  end

  local function stop_all()
    for bufnr in pairs(buffers) do
      stop(bufnr)
    end
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    once = true,
    callback = function()
      stop_all()
    end,
  })

  local function start(cmd)
    local bufnr = vim.api.nvim_get_current_buf()

    -- Stop any existing job for this buffer before starting a new one
    stop(bufnr)

    if opts.on_start then
      opts.on_start()
    else
      notify.info("Start HotReload", label)
    end

    local s = {}
    buffers[bufnr] = s

    s.job_id = vim.fn.jobstart(cmd, {
      on_exit = function()
        if opts.on_exit then
          opts.on_exit()
        else
          notify.info("Compile finished", label)
        end
        if buffers[bufnr] == s then
          buffers[bufnr] = nil
        end
      end,
    })

    s.autocmd_id = vim.api.nvim_create_autocmd("BufDelete", {
      buffer = bufnr,
      once = true,
      callback = function()
        stop(bufnr)
      end,
    })
  end

  if opts.stop_command then
    vim.api.nvim_create_user_command(opts.stop_command, stop_current, {
      desc = ("Stop %s hot reload"):format(label),
      nargs = 0,
    })
  end

  return { start = start, stop = stop_current, stop_all = stop_all }
end

return M
