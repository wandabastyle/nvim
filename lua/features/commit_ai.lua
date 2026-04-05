local M = {}

local function current_buffer_dir()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return vim.uv.cwd()
  end
  return vim.fs.dirname(file)
end

local function find_git_root(callback)
  local from = current_buffer_dir()
  vim.system(
    { "git", "-C", from, "rev-parse", "--show-toplevel" },
    { text = true },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          callback(nil)
          return
        end

        local root = vim.trim(result.stdout or "")
        if root == "" then
          callback(nil)
          return
        end

        callback(root)
      end)
    end
  )
end

local function ai_script_path()
  return vim.fn.stdpath("config") .. "/scripts/git-commit-ai.py"
end

local function suggest_message(git_root, callback)
  vim.system(
    { "python3", ai_script_path() },
    { cwd = git_root, text = true },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          callback(nil, vim.trim(result.stderr or "AI helper failed"))
          return
        end

        local msg = vim.trim(result.stdout or "")
        if msg == "" then
          callback(nil, "AI helper returned an empty commit message")
          return
        end

        callback(msg)
      end)
    end
  )
end

local function run_commit(git_root, message, callback)
  vim.system(
    { "git", "commit", "-a", "-m", message },
    { cwd = git_root, text = true },
    function(result)
      vim.schedule(function()
        if result.code == 0 then
          callback(true, vim.trim(result.stdout or ""))
          return
        end

        local err = vim.trim(result.stderr or "")
        if err == "" then
          err = vim.trim(result.stdout or "Unknown git commit error")
        end

        callback(false, err)
      end)
    end
  )
end

function M.save_and_commit()
  local ok = pcall(vim.cmd.write)
  if not ok then
    vim.notify("Could not save current buffer", vim.log.levels.ERROR)
    return
  end

  find_git_root(function(git_root)
    if not git_root then
      vim.notify("Not inside a git repository", vim.log.levels.ERROR)
      return
    end

    suggest_message(git_root, function(suggested, err)
      if err then
        vim.notify(err, vim.log.levels.ERROR)
        return
      end

      vim.ui.input({
        prompt = "Git commit message: ",
        default = suggested,
      }, function(input)
        if input == nil then
          vim.notify("Commit canceled", vim.log.levels.INFO)
          return
        end

        local message = vim.trim(input)
        if message == "" then
          vim.notify("Empty commit message. Aborted.", vim.log.levels.WARN)
          return
        end

        run_commit(git_root, message, function(success, output)
          if success then
            local msg = output ~= "" and output or "Commit created"
            vim.notify(msg, vim.log.levels.INFO)
            return
          end

          vim.notify("git commit failed: " .. output, vim.log.levels.ERROR)
        end)
      end)
    end)
  end)
end

return M
