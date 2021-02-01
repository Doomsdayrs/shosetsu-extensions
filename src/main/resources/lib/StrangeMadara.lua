-- {"ver":"1.0.0","author":"Doomsdayrs","dep":["url"]}
--- This is a strange Madara
--- Looks like Madara, but is not.

local text = function(v)
	return v:text()
end

local settings = {}

local defaults = {
	latestNovelSel = "div.item-thumb",
	hasCloudFlare = false,
	hasSearch = true,
	brokenURLS = false
}

function defaults:latest(data)
	local document = GETDocument(self.baseURL .. "/list/" .. data[PAGE])

	return map(document:select(self.latestNovelSel), function(
	---@type Element
			v
	)
		local item = v:selectFirst("a")
		local imageItem = v:selectFirst("img")

		return Novel {
			title = item:attr("title"),
			link = item:attr("href"),
			imageURL = self.baseURL .. imageItem:attr("src")
		}
	end)
end

--- This broken madara has problematic linking
---@param brokenLink string
---@return string
function defaults:getLinkFrom404(brokenLink)
	if ~self.brokenURLS then
		return brokenLink
	end
	local linkDocument = GETDocument(brokenLink)
	local linkDocMain = linkDocument:selectFirst("main")
	return linkDocMain:selectFirst("a"):attr("href")
end

function defaults:recent()
	local document = GETDocument(self.baseURL .. "/recents")
	map(
			document:select("div.item-thumb"),
			function(
			---@type Element
					v
			)
				local item = v:selectFirst("a")
				local itemImage = item:selectFirst("img")

				-- Requires a second link
				local linkDocURL = self.baseURL .. item:attr("href")

				return Novel {
					title = item:attr("title"),
					link = self:getLinkFrom404(linkDocURL),
					imageURL = self.baseURL .. itemImage:attr("src")
				}
			end
	)

end

--- Create a search string
---@param tbl table
---@return string
function defaults:createSearchString(tbl)
	--- @type string
	local query = tbl[QUERY]
	return self.baseURL .. "/search.ajax?query=" .. query:gsub(" ", "-")
end

function defaults:search(data)
	local url = self.createSearchString(data)
	local document = GETDocument(url)
	map(document:select("a"), function(v)
		Novel {
			title = v:attr("title"),
			link = self:getLinkFrom404(v:attr("href"))
		}
	end)
	return
end

--- Gets the passage of a chapter
---@param url string
---@return string
function defaults:getPassage(url)
	return table.concat(map(GETDocument(self.expandURL(url)):select("div.text-left p"), text), "\n")
end

--- Parses a novels page
---@param url string
---@param loadChapters boolean
---@return NovelInfo
function defaults:parseNovel(url, loadChapters)
	local doc = GETDocument(self.expandURL(url))

	local elements = doc:selectFirst("div.post-content"):select("div.post-content_item")
	local info = NovelInfo {
		description = doc:selectFirst("p"):text(),
		authors = map(elements:get(3):select("a"), text),
		artists = map(elements:get(4):select("a"), text),
		genres = map(elements:get(5):select("a"), text),
		title = doc:selectFirst(self.novelPageTitleSel):text(),
		imageURL = doc:selectFirst("div.summary_image"):selectFirst("img.img-responsive"):attr("src"),
		status = doc:selectFirst("div.post-status"):select("div.post-content_item"):get(1)
		            :select("div.summary-content"):text() == "OnGoing"
				and NovelStatus.PUBLISHING or NovelStatus.COMPLETED
	}

	-- Chapters
	if loadChapters then
		local e = doc:select("li.wp-manga-chapter")
		local a = e:size()
		local l = AsList(map(e, function(v)
			local c = NovelChapter()
			c:setLink(self.shrinkURL(v:selectFirst("a"):attr("href")))
			c:setTitle(v:selectFirst("a"):text())

			local i = v:selectFirst("i")
			c:setRelease(i and i:text() or v:selectFirst("img[alt]"):attr("alt"))
			c:setOrder(a)
			a = a - 1
			return c
		end))
		Reverse(l)
		info:setChapters(l)
	end

	return info
end

function defaults:expandURL(url)
	-- TODO Fix
	return self.baseURL .. "/" .. self.shrinkURLNovel .. "/" .. url
end

function defaults:shrinkURL(url)
	-- TODO Fix
	return url:gsub("https?://.-/" .. self.shrinkURLNovel .. "/", "")
end

return function(baseURL, _self)
	_self = setmetatable(_self or {}, { __index = function(_, k)
		local d = defaults[k]
		return (type(d) == "function" and wrap(_self, d) or d)
	end })

	_self.genres_map = {}
	_self["searchFilters"] = {  }
	_self["baseURL"] = baseURL
	_self["listings"] = {
		Listing("Default", true, _self.latest),
		Listing("Recently loaded", false, _self.recent)
	}
	_self["updateSetting"] = function(id, value)
		settings[id] = value
	end

	return _self
end