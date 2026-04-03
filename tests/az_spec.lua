local az = require("azure.az")

describe("az.run_az_command", function()
  local original_system = vim.system

  after_each(function()
    vim.system = original_system
  end)

  it("returns stdout on success", function()
    vim.system = function(_, _opts)
      return {
        wait = function()
          return { code = 0, stdout = "hello\n", stderr = "" }
        end,
      }
    end

    local result, err = az.run_az_command({ "az", "version" })
    assert.equals("hello\n", result)
    assert.is_nil(err)
  end)

  it("returns nil and stderr on non-zero exit code", function()
    vim.system = function(_, _opts)
      return {
        wait = function()
          return { code = 1, stdout = "", stderr = "az: command not found" }
        end,
      }
    end

    local result, err = az.run_az_command({ "az", "version" })
    assert.is_nil(result)
    assert.equals("az: command not found", err)
  end)

  it("falls back to stdout when stderr is empty on error", function()
    vim.system = function(_, _opts)
      return {
        wait = function()
          return { code = 1, stdout = "some error in stdout", stderr = "" }
        end,
      }
    end

    local result, err = az.run_az_command({ "az", "version" })
    assert.is_nil(result)
    assert.equals("some error in stdout", err)
  end)
end)

describe("az.fetch_app_settings", function()
  local original_system = vim.system
  local notifications

  before_each(function()
    notifications = {}
    vim.notify = function(msg, level)
      table.insert(notifications, { msg = msg, level = level })
    end
  end)

  after_each(function()
    vim.system = original_system
  end)

  it("returns a flat key→value table on success", function()
    local json = vim.json.encode({
      { name = "FOO", value = "bar" },
      { name = "BAZ", value = "qux" },
    })
    vim.system = function(_, _opts)
      return { wait = function() return { code = 0, stdout = json, stderr = "" } end }
    end

    local result = az.fetch_app_settings("my-app", "my-rg")
    assert.same({ FOO = "bar", BAZ = "qux" }, result)
    assert.same({}, notifications)
  end)

  it("returns nil and notifies on az CLI error", function()
    vim.system = function(_, _opts)
      return { wait = function() return { code = 1, stdout = "", stderr = "Not logged in" } end }
    end

    local result = az.fetch_app_settings("my-app", "my-rg")
    assert.is_nil(result)
    assert.equals(1, #notifications)
    assert.equals(vim.log.levels.ERROR, notifications[1].level)
  end)

  it("returns nil and notifies on invalid JSON", function()
    vim.system = function(_, _opts)
      return { wait = function() return { code = 0, stdout = "not json", stderr = "" } end }
    end

    local result = az.fetch_app_settings("my-app", "my-rg")
    assert.is_nil(result)
    assert.equals(1, #notifications)
    assert.equals(vim.log.levels.ERROR, notifications[1].level)
  end)
end)
