-- {"id":258,"version":"0.1.3","author":"Doomsdayrs","repo":""}

local baseURL = "https://fastnovel.net"
local encode = Require("url").encode
local settings = {}

local function setSettings(setting)
	settings = setting
end

---@return string @passage of chapter, If nothing can be parsed, then the text should describe why there isn't a chapter
local function getPassage(url)
	return table.concat(map(GETDocument(url):select("div.box-player"):select("p"), function(v)
		return v:text()
	end), "\n")
end

---@param url string
---@return NovelInfo
local function parseNovel(url)
	local novelPage = NovelInfo()
	local document = GETDocument(url)

	novelPage:setImageURL(document:selectFirst("div.book-cover"):attr("data-original"))
	novelPage:setTitle(document:selectFirst("h1.name"):text())
	novelPage:setDescription(table.concat(map(document:select("div.film-content"):select("p"), function(v)
		return v:text()
	end), "\n"))

	local elements = document:selectFirst("ul.meta-data"):select("li")
	novelPage:setAuthors(map(elements:get(0):select("a"),
			function(v)
				return v:text()
			end))
	novelPage:setGenres(map(elements:get(1):select("a"), function(v)
		return v:text()
	end))

	novelPage:setStatus(NovelStatus(
			elements:get(2):selectFirst("strong"):text():match("Completed") and 1 or 0
	))

	-- chapters
	local volumeName = ""
	local chapterIndex = 0
	local chapters = AsList(map2flat(
			document:selectFirst("div.block-film"):select("div.book"),
			function(element)
				volumeName = element:selectFirst("div.title"):selectFirst("a.accordion-toggle"):text()
				return element:select("li")
			end,
			function(element)
				local chapter = NovelChapter()
				local data = element:selectFirst("a.chapter")
				chapter:setTitle(volumeName .. " " .. data:text())
				chapter:setLink(baseURL .. data:attr("href"))
				chapter:setOrder(chapterIndex)
				chapterIndex = chapterIndex + 1
				return chapter
			end))

	novelPage:setChapters(chapters)
	return novelPage
end

---@return table @Novel array list
local function parseLatest(data)
	return map(GETDocument(baseURL .. "/list/latest.html?page=" .. data[PAGE]):selectFirst("ul.list-film"):select("li.film-item"), function(v)
		local novel = Novel()
		local data = v:selectFirst("a")
		novel:setLink(baseURL .. data:attr("href"))
		novel:setTitle(data:attr("title"))
		novel:setImageURL(data:selectFirst("div.img"):attr("data-original"))
		return novel
	end)
end

---@return table @Novel array list
local function search(data)
	return map(GETDocument(baseURL .. "/search/" .. encode(data[QUERY])):select("ul.list-film"), function(v)
		local novel = Novel()
		local novelData = v:selectFirst("a")
		novel:setLink(baseURL .. novelData:attr("href"))
		novel:setTitle(novelData:attr("title"))
		novel:setImageURL(novelData:selectFirst("div.img"):attr("data-original"))
		return novel
	end)
end

return {
	id = 258,
	name = "FastNovel",
	baseURL = baseURL,
	imageURL = "https://fastnovel.net/skin/images/logo.png",
	listings = {
		Listing("Latest", true, parseLatest)
	},
	---@param url string
	---@param key int
	shrinkURL = function(url, key)
		return url:gsub(baseURL .. "/", "")
	end,
	---@param url string
	---@param key int
	expandURL = function(url, key)
		return baseURL .. "/" .. url
	end,
	getPassage = getPassage,
	parseNovel = parseNovel,
	search = search,
	isSearchIncrementing = false,
}
