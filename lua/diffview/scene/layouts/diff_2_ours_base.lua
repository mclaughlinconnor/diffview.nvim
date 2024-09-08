local async = require("diffview.async")
local Window = require("diffview.scene.window").Window
local Diff4 = require("diffview.scene.layouts.diff_4").Diff4
local oop = require("diffview.oop")

local api = vim.api
local await = async.await

local M = {}

---@class Diff2OursBase : Diff2
---@field a Window
---@field b Window
---@field c Window
---@field d Window
local Diff2OursBase = oop.create_class("Diff2OursBase", Diff4)

Diff2OursBase.name = "diff2_oursbase"

function Diff2OursBase:init(opt)
  self:super(opt)
end

---@override
---@param self Diff2OursBase
---@param pivot integer?
Diff2OursBase.create = async.void(function(self, pivot)
  self:create_pre()
  local curwin

  pivot = pivot or self:find_pivot()
  assert(api.nvim_win_is_valid(pivot), "Layout creation requires a valid window pivot!")

  for _, win in ipairs(self.windows) do
    if win.id ~= pivot then
      win:close(true)
    end
  end

  api.nvim_win_call(pivot, function()
    vim.cmd("aboveleft vsp")
    curwin = api.nvim_get_current_win()

    if self.a then
      self.a:set_id(curwin)
    else
      self.a = Window({ id = curwin })
    end
  end)

  api.nvim_win_call(pivot, function()
    vim.cmd("aboveleft vsp")
    curwin = api.nvim_get_current_win()

    if self.b then
      self.b:set_id(curwin)
    else
      self.b = Window({ id = curwin })
    end
  end)

  api.nvim_win_close(pivot, true)
  self.windows = {
    self.a,
    self.b,
    -- self.c,
    -- self.d,
  }
  await(self:create_post())
end)


---@param self Diff4
---@param entry FileEntry
Diff2OursBase.use_entry = async.void(function(self, entry)
  local layout = entry.layout --[[@as Diff4 ]]
  assert(layout:instanceof(Diff4))

  self:set_file_a(layout.a.file)
  self:set_file_b(layout.d.file)

  if self:is_valid() then
    await(self:open_files())
  end
end)

M.Diff2OursBase = Diff2OursBase
return M
