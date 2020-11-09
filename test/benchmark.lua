--
-- benchmark.lua
-- Copyright (C) 2020 romgrk <romgrk@arch>
--
-- Distributed under terms of the MIT license.
--

local original = require'fzy_lua'
local native = require'fzy_native'

local function lines_from(file)
  lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end


function benchmark(fn)
  local total = 0
  -- Warmup
  for i = 1, 5 do
    total = total + #fn()
  end

  local start = os.clock()
  total = 0
  for i = 1, 200 do
    total = total + #fn()
  end
  local end_ = os.clock()
  return (end_ - start) * 1000, total
end


function filter(fzy, needle, lines)
  results = {}
  for i, line in ipairs(lines) do
    if fzy.has_match(needle, line) then
      local positions = fzy.positions(needle, line)
      table.insert(results, {line, positions})
    end
  end
  return results
end


function main()
  local lines = lines_from('./files.txt')

  print('Lines: ' .. #lines)
  print('')

  local time, total = benchmark(function() return filter(native, 'f', lines) end)
  print('Native:')
  print(' -> Total: ' .. total)
  print(' -> Time:  ' .. time .. ' ms')

  local time, total = benchmark(function() return filter(original, 'f', lines) end)
  print('Lua:')
  print(' -> Total: ' .. total)
  print(' -> Time:  ' .. time .. ' ms')
end

main()
