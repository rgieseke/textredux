--[[
The matcher module provides easy and advanced matching of strings.

@author Nils Nordman <nino at nordman.org>
@copyright 2011-2012
@license MIT (see LICENSE)
@module _M.textui.util.matcher
]]

local _G, string, table, math = _G, string, table, math
local ipairs, type, setmetatable, tostring =
      ipairs, type, setmetatable, tostring

local matcher = {}
local _ENV = matcher
if setfenv then setfenv(1, _ENV) end

--[[ Constructs a new matcher.
@param candidates The candidates to consider for matching. A table of either
string, or tables containing strings.
@param search_case_insensitive Whether searches are case insensitive or not.
Defaults to `true`.
@param search_fuzzy Whether fuzzy searching should be used in addition to
explicit matching. Defaults to `true`.
]]
function new(candidates, search_case_insensitive, search_fuzzy)
  local m = {
    search_case_insensitive = search_case_insensitive,
    search_fuzzy = search_fuzzy
  }
  setmetatable(m, { __index = matcher })
  m:_set_candidates(candidates)
  return m
end

-- Applies search matchers on a line.
-- @param line The line to match
-- @param matchers The search matchers to apply
-- @return A numeric score if the line matches or nil otherwise. For scoring,
-- lower is better.
local function match_score(line, matchers)
  local score = 0

  for _, matcher in ipairs(matchers) do
    local matcher_score = matcher(line)
    if not matcher_score then return nil end
    score = score + matcher_score
  end
  return score
end

-- Matches search against the candidates.
-- @param search The search string to match
-- @return A table of matching candidates, ordered by relevance.
function matcher:match(search)
  if not search or #search == 0 then return self.candidates end
  local cache = self.cache
  if self.search_case_insensitive then search = search:lower() end
  local matches = cache.matches[search] or {}
  if #matches > 0 then return matches end
  local lines = cache.lines[string.sub(search, 1, -2)] or self.lines
  local matchers = self:_matchers_for_search(search)

  local matching_lines = {}
  for i, line in ipairs(lines) do
    local score = match_score(line.text, matchers)
    if score then
      matches[#matches + 1] = { index = line.index, score = score }
      matching_lines[#matching_lines + 1] = line
    end
  end
  cache.lines[search] = matching_lines

  table.sort(matches, function(a ,b) return a.score < b.score end)
  local matching_candidates = {}
  for _, match in ipairs(matches) do
    matching_candidates[#matching_candidates + 1] = self.candidates[match.index]
  end
  self.cache.matches[search] = matching_candidates
  return matching_candidates
end

function matcher:_set_candidates(candidates)
  self.candidates = candidates
  self.cache = {
    lines = {},
    matches = {}
  }
  local lines = {}
  local fuzzy_score_penalty = 0

  for i, candidate in ipairs(candidates) do
    if type(candidate) ~= 'table' then candidate = { candidate } end
    local text = table.concat(candidate, ' ')
    if self.search_case_insensitive then text = text:lower() end
    lines[#lines + 1] = {
      text = text,
      index = i
    }
    fuzzy_score_penalty = math.max(fuzzy_score_penalty, #text)
  end
  self.lines = lines
  self.fuzzy_score_penalty = fuzzy_score_penalty
end

local pattern_escapes = {}
for c in string.gmatch('^$()%.[]*+-?', '.') do pattern_escapes[c] = '%' .. c end

local function fuzzy_search_pattern(search)
  local pattern = ''
  for i = 1, #search do
    local c = search:sub(i, i)
    c = pattern_escapes[c] or c
    pattern = pattern .. c .. '.-'
  end
  return pattern
end

--- Creates matches for the specified search
-- @param search_string The search string
-- @return A table of matcher functions, each taking a line as parameter and
-- returning a score (or nil for no match).
function matcher:_matchers_for_search(search_string)
  local fuzzy = self.search_fuzzy
  local fuzzy_penalty = self.fuzzy_score_penalty
  local groups = {}
  for part in search_string:gmatch('%S+') do groups[#groups + 1] = part end
  local matchers = {}

  for _, search in ipairs(groups) do
    local fuzzy_pattern = fuzzy and fuzzy_search_pattern(search)
    matchers[#matchers + 1] = function(line)
      local score = line:find(search, 1, true)
      if not score and fuzzy then
        local start_pos, end_pos = line:find(fuzzy_pattern)
        if start_pos then
          score = (end_pos - start_pos) + fuzzy_penalty
        end
      end
      return score and (score + #line) or nil
    end
  end
  return matchers
end

return matcher
