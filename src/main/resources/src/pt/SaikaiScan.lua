-- {"id":2443,"ver":"1.0.2","libVer":"1.0.0","author":"Doomsdayrs","dep":["url>=1.0.0"]}

local baseURL = "https://saikaiscan.com.br"
local settings = {}
local encode = Require("url").encode

local FILTER_TIPO_KEY = 91
local TIPO_V = { [0] = "novels", [1] = "manhuas", [2] = "curiosities" }

--- @param chapterURL string
--- @return string
local function getPassage(chapterURL)
	local lines = GETDocument(baseURL..chapterURL):selectFirst("div.full-text"):select("p")
	local passage = "\n"
	map(lines, function(e)
		passage = passage .. e:text() .. "\n"
	end)
	return passage
end

--- @param novelURL string
--- @return NovelInfo
local function parseNovel(novelURL)
	local novelInfo = NovelInfo()
	local document = GETDocument(baseURL..novelURL)
	local infos = document:select("div.info")

	novelInfo:setTitle(document:selectFirst("h2"):text())
	novelInfo:setImageURL(document:selectFirst("div.cover"):select("img"):attr("data-src"))
	if infos:size() > 0 then
		novelInfo:setAlternativeTitles({ infos:get(0):text() })
		novelInfo:setGenres({ infos:get(1):text() })
		novelInfo:setAuthors({ infos:get(2):text() })
		local st = infos:get(3):text()
		if st == "Em Tradução" then
			novelInfo:setStatus(NovelStatus(0))
		else
			novelInfo:setStatus(NovelStatus(3))
		end
	end

	local description = ""
	map(document:select("div.summary-text"):select("span"), function(e)
		description = description .. e:text() .. "\n"
	end)
	novelInfo:setDescription(description)

	local chaptersDocs = document:selectFirst("div.project-chapters"):select("div.chapters")

	local chapterCount = 0

	local chapters = map2flat(chaptersDocs, function(e)
		return e:select("a")
	end, function(e)
		local chapter = NovelChapter()
		chapter:setTitle(e:text())
		chapter:setLink(e:attr("href"))
		chapter:setOrder(chapterCount)
		chapterCount = chapterCount + 1
		return chapter
	end)
	novelInfo:setChapters(AsList(chapters))
	return novelInfo
end

--- @param filters table @of applied filter values [QUERY] is the search query, may be empty
local function search(filters)
	if filters[PAGE] == 0 then
		filters[PAGE] = 1
	end
	local query = encode(filters[QUERY])
	local document = GETDocument(baseURL .. "/busca?q=" .. query .. "&page=" .. filters[PAGE])
	local divs = document:select("div")
	for i = 0, divs:size() - 1 do
		if divs:get(i):id() == "news-content" then
			local listing = divs:get(i)
			return map(listing:select("li"), function(e)
				local n = Novel()
				n:setTitle(e:selectFirst("h3"):text())
				local image = e:selectFirst("div.image")
				n:setImageURL(image:attr("data-src"))
				n:setLink(image:selectFirst("a"):attr("href"))
				return n
			end)
		end
	end
	return {}
end

return {
	id = 2443,
	name = "Saikai Scan",
	baseURL = baseURL,

	-- Optional values to change
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/src/main/resources/icons/SaikaiScan.png",
	hasSearch = false,

	-- Must have at least one value
	listings = {
		Listing("Últimas atualizações", false, function(data)
			local doc = GETDocument(baseURL)
			local type = data[FILTER_TIPO_KEY]
			local itemList = doc:selectFirst("ul." .. TIPO_V[type])
			---@type Elements
			local items
			if type == 0 then
				items = itemList:select("li.novel-item")
			elseif type == 1 then
				items = itemList:select("li.manhua-item")
			else
				items = itemList:select("li")
			end
			return map(items, function(e)
				local novel = Novel()
				novel:setTitle(e:selectFirst("h3"):text())
				novel:setImageURL(baseURL .. e:selectFirst("div.image"):attr("data-src"))
				novel:setLink(e:selectFirst("a"):attr("href"))
				return novel
			end)
		end)
	},

	-- Optional if usable
	searchFilters = {
		DropdownFilter(FILTER_TIPO_KEY, "Tipo", { "Novels", "Comics", "Curiosidades" })
	},

	shrinkURL = function(url)
		return url:gsub(baseURL, "")
	end,

	expandURL = function(url)
		return baseURL .. url
	end,

	-- Default functions that have to be set
	getPassage = getPassage,
	parseNovel = parseNovel,
}
