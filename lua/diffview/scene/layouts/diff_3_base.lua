local async = require("diffview.async")
local Window = require("diffview.scene.window").Window
local Diff4 = require("diffview.scene.layouts.diff_4").Diff4
local oop = require("diffview.oop")

local api = vim.api
local await, pawait = async.await, async.pawait
local logger = DiffviewGlobal.logger

local M = {}

---@class Diff3Base : Diff4
---@field a Window
---@field b Window
---@field c Window
---@field d Window
local Diff3Base = oop.create_class("Diff3Base", Diff4)

Diff3Base.name = "diff3_base"

function Diff3Base:init(opt)
  self:super(opt)
end

---@override
---@param self Diff3Base
---@param pivot integer?
Diff3Base.create = async.void(function(self, pivot)
  self:create_pre()
  local curwin

  pivot = pivot or self:find_pivot()
  assert(api.nvim_win_is_valid(pivot), "Layout creation requires a valid window pivot!")

  for _, win in ipairs(self.windows) do
    if win.id ~= pivot then
      win:close(true)
    end
  end

  -- api.nvim_win_call(pivot, function()
  --   vim.cmd("belowright sp")
  --   curwin = api.nvim_get_current_win()
  --
  --   if self.d then
  --     self.d:set_id(curwin)
  --   else
  --     self.d = Window({ id = curwin })
  --   end
  -- end)

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

  api.nvim_win_call(pivot, function()
    vim.cmd("aboveleft vsp")
    curwin = api.nvim_get_current_win()

    if self.c then
      self.c:set_id(curwin)
    else
      self.c = Window({ id = curwin })
    end
  end)

  self.a.file.get_data = function(_kind, path, pos)
    local text = vim.system({"java", "-jar", "/home/connor/Development/haxe-ij-merge/haxe-ij-merge.jar", "getSide", path, pos, "1"}):wait()
    return vim.split(text.stdout, "\n")
  end

  self.c.file.get_data = function(_kind, path, pos)
    local text = vim.system({"java", "-jar", "/home/connor/Development/haxe-ij-merge/haxe-ij-merge.jar", "getSide", path, pos, "1"}):wait()
    return vim.split(text.stdout, "\n")
  end

  local ok, err = pawait(self.b.file.create_buffer, self.b.file)
  if ok and not self.b.file:is_valid() then
    ok = false
    err = "The file buffer is invalid!"
  end

  if not ok then
    logger:error(err)
    print(fmt("Failed to create diff buffer: '%s:%s'", self.b.file.rev, self.b.file.path), true)
  end

  local baseText = vim.system({"java", "-jar", "/home/connor/Development/haxe-ij-merge/haxe-ij-merge.jar", "getSide", self.b.file.path, "base", "1"}):wait()
  vim.api.nvim_buf_set_lines(self.b.file.bufnr, 0, -1, false, vim.split(baseText.stdout, "\n"))


  api.nvim_win_close(pivot, true)
  self.windows = {
    self.a,
    self.b,
    self.c,
    -- self.d,
  }
  await(self:create_post())
end)

---@param self Diff4
---@param entry FileEntry
Diff3Base.use_entry = async.void(function(self, entry)
  local layout = entry.layout --[[@as Diff4 ]]
  assert(layout:instanceof(Diff4))

  self:set_file_a(layout.a.file)
  self:set_file_b(layout.b.file)
  self:set_file_c(layout.c.file)
  self:set_file_d(layout.d.file)

  if self:is_valid() then
    await(self:open_files())
  end
end)

M.Diff3Base = Diff3Base
return M
