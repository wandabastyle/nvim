local M = {}

-- Return the directory of the current buffer, or the current working directory.
local function current_buffer_dir()
  local file = vim.api.nvim_buf_get_name(0)

  if file == "" then
    return vim.uv.cwd()
  end

  return vim.fn.fnamemodify(file, ":p:h")
end

-- Find the git repo root for the current buffer context.
local function in_git_repo(callback)
  local buffer_dir = current_buffer_dir()

  vim.system(
    { "git", "-C", buffer_dir, "rev-parse", "--show-toplevel" },
    { text = true },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          callback(nil)
          return
        end

        local git_root = vim.trim(result.stdout or "")

        if git_root == "" then
          callback(nil)
          return
        end

        callback(git_root)
      end)
    end
  )
end

-- Run the local Python helper and return a suggested commit message.
local function run_commit_message_ai(git_root, callback)
  local script = vim.fn.expand("~/.config/nvim/scripts/git-commit-ai.py")

  vim.system(
    { "python3", script },
    { cwd = git_root, text = true },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          local stderr_text = vim.trim(result.stderr or "")
          callback(nil, "AI script failed: " .. stderr_text)
          return
        end

        local suggestion = vim.trim(result.stdout or "")

        if suggestion == "" then
          callback(nil, "AI script returned an empty message")
          return
        end

        callback(suggestion, nil)
      end)
    end
  )
end

-- Run `git commit -a -m` with the final message.
local function commit_with_message(git_root, message, callback)
  vim.system(
    -- `-a` includes all modified tracked files automatically.
    { "git", "commit", "-a", "-m", message },
    { cwd = git_root, text = true },
    function(result)
      vim.schedule(function()
        if result.code == 0 then
          callback(true, vim.trim(result.stdout or ""))
          return
        end

        local stderr_text = vim.trim(result.stderr or "")

        if stderr_text == "" then
          stderr_text = vim.trim(result.stdout or "")
        end

        callback(false, stderr_text)
      end)
    end
  )
end

-- Main workflow for <leader>gw: write buffer -> suggest -> edit -> commit.
local function git_write()
  local wrote_ok = pcall(vim.cmd, "write")

  if not wrote_ok then
    vim.notify("Could not save current buffer", vim.log.levels.ERROR)
    return
  end

  in_git_repo(function(git_root)
    if not git_root then
      vim.notify("Not inside a git repository", vim.log.levels.ERROR)
      return
    end

    run_commit_message_ai(git_root, function(suggested_message, err)
      if err then
        vim.notify(err, vim.log.levels.ERROR)
        return
      end

      vim.ui.input(
        {
          prompt = "Git commit message: ",
          default = suggested_message,
        },
        function(input)
          if input == nil then
            vim.notify("Commit canceled", vim.log.levels.INFO)
            return
          end

          local final_message = vim.trim(input)

          if final_message == "" then
            vim.notify("Empty commit message. Aborted.", vim.log.levels.INFO)
            return
          end

          commit_with_message(git_root, final_message, function(ok, output)
            if ok then
              local success_text = "Commit created successfully"

              if output ~= "" then
                success_text = success_text .. ": " .. output
              end

              vim.notify(success_text, vim.log.levels.INFO)
              return
            end

            vim.notify(
              "git commit failed: " .. output,
              vim.log.levels.ERROR
            )
          end)
        end
      )
    end)
  end)
end

function M.setup()
  vim.keymap.set("n", "<leader>gw", git_write, {
    desc = "Save and commit with AI message",
    silent = true,
  })
end

M.in_git_repo = in_git_repo
M.run_commit_message_ai = run_commit_message_ai
M.commit_with_message = commit_with_message
M.git_write = git_write

return M
