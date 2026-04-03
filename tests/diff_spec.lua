local diff = require("azure.diff")

describe("diff.compute", function()
  it("returns empty result for empty inputs", function()
    local result = diff.compute({}, {})
    assert.same({}, result.added)
    assert.same({}, result.changed)
    assert.same({}, result.unchanged)
    assert.same({}, result.azure_only)
  end)

  it("detects a key present locally but not in Azure as added", function()
    local result = diff.compute({ MY_KEY = "hello" }, {})
    assert.same({ MY_KEY = "hello" }, result.added)
    assert.same({}, result.changed)
    assert.same({}, result.unchanged)
    assert.same({}, result.azure_only)
  end)

  it("detects a key present in Azure but not locally as azure_only", function()
    local result = diff.compute({}, { MY_KEY = "hello" })
    assert.same({}, result.added)
    assert.same({}, result.changed)
    assert.same({}, result.unchanged)
    assert.same({ MY_KEY = "hello" }, result.azure_only)
  end)

  it("detects matching keys with same value as unchanged", function()
    local result = diff.compute({ FOO = "bar" }, { FOO = "bar" })
    assert.same({}, result.added)
    assert.same({}, result.changed)
    assert.same({ FOO = "bar" }, result.unchanged)
    assert.same({}, result.azure_only)
  end)

  it("detects matching keys with different values as changed", function()
    local result = diff.compute({ FOO = "local_val" }, { FOO = "azure_val" })
    assert.same({}, result.added)
    assert.same({ FOO = { local_val = "local_val", azure_val = "azure_val" } }, result.changed)
    assert.same({}, result.unchanged)
    assert.same({}, result.azure_only)
  end)

  it("compares values as strings (number 42 matches string '42')", function()
    local result = diff.compute({ PORT = "42" }, { PORT = 42 })
    assert.same({}, result.changed)
    assert.same({ PORT = "42" }, result.unchanged)
  end)

  it("handles a mixed scenario with all four categories", function()
    local local_vals = {
      ADDED_KEY   = "new",
      CHANGED_KEY = "local_value",
      SAME_KEY    = "same",
    }
    local azure_vals = {
      CHANGED_KEY  = "azure_value",
      SAME_KEY     = "same",
      AZURE_KEY    = "only_in_azure",
    }

    local result = diff.compute(local_vals, azure_vals)

    assert.same({ ADDED_KEY = "new" }, result.added)
    assert.same({ CHANGED_KEY = { local_val = "local_value", azure_val = "azure_value" } }, result.changed)
    assert.same({ SAME_KEY = "same" }, result.unchanged)
    assert.same({ AZURE_KEY = "only_in_azure" }, result.azure_only)
  end)

  it("handles multiple added keys", function()
    local result = diff.compute({ A = "1", B = "2", C = "3" }, {})
    assert.same({ A = "1", B = "2", C = "3" }, result.added)
    assert.same({}, result.azure_only)
  end)

  it("handles multiple azure_only keys", function()
    local result = diff.compute({}, { X = "10", Y = "20" })
    assert.same({}, result.added)
    assert.same({ X = "10", Y = "20" }, result.azure_only)
  end)
end)
