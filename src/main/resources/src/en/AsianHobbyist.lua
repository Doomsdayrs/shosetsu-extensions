-- {"id":951,"ver":"1.0.1","libVer":"1.0.0","author":"Doomsdayrs"}

local baseURL = "https://www.asianhobbyist.com"

---@param v Element
local function textOf(v)
	return v:text()
end

---@param url string
---@param type int
local function shrinkURL(url, type)
	if type == KEY_NOVEL_URL then
		return url:gsub(baseURL .. "/series/", ""):gsub("/", "")
	else
		return url:gsub(baseURL .. "/", ""):gsub("/", "")
	end
end

---@param url string
---@param type int
local function expandURL(url, type)
	if type == KEY_NOVEL_URL then
		return baseURL .. "/series/" .. url
	else
		return baseURL .. "/" .. url
	end
end

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
	local d = GETDocument(expandURL(chapterURL, KEY_CHAPTER_URL))
	local htmlBody = d:selectFirst("div.entry-content")
	local htmlLines = htmlBody:select("p")
	local lines = map(htmlLines, textOf)
	return table.concat(lines, "\n")
end

--- @param data table
local function search(data)
	local queryContent = data[QUERY]
	local doc = RequestDocument(
			POST(baseURL .. "/wp-admin/admin-ajax.php", nil,
					FormBodyBuilder()
							:add("action", "gsr")
							:add("enc", "25e9bf9508")
							:add("src", queryContent):build())
	)

	return map(doc:select("li.flex"), function(v)
		local htmlTitle = v:selectFirst("div.title"):selectFirst("a")
		return Novel {
			title = htmlTitle:attr("title"),
			imageURL = v:selectFirst("img"):attr("src"),
			link = shrinkURL(htmlTitle:attr("href"), KEY_NOVEL_URL)
		}
	end)
end
--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
	local document = GETDocument(expandURL(novelURL, KEY_NOVEL_URL))
	return NovelInfo {
		title = document:selectFirst("h1.entry-title"):text(),
		description = document:selectFirst("div.description"):selectFirst("div"):text(),
		imageURL = document:selectFirst("div.thumb"):selectFirst("img"):attr("data-lazy-src"),
		chapters = AsList(
				map(document:select("div.row.flex.fn"), function(v)
					local divs = v:select("div")
					local a = v:selectFirst("a")
					return NovelChapter {
						order = tonumber(divs:get(0):text()),
						release = divs:get(1):text(),
						title = a:text(),
						link = shrinkURL(a:attr("href"), KEY_CHAPTER_URL),
					}
				end)
		)
	}

end
return {
	id = 951,
	name = "Asian Hobbyist",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/src/main/resources/icons/AsianHobbyist.png",
	hasSearch = true,
	listings = {
		Listing("Latest", false, function()
			local document = GETDocument(baseURL)
			return map(document:select("li.item"), function(v)
				local a = v:selectFirst("a")
				local image = a:selectFirst("img")
				return Novel {
					title = image:attr("alt"),
					imageURL = image:attr("href"),
					link = shrinkURL(a:attr("href"), KEY_NOVEL_URL)
				}
			end)
		end)
	},
	parseNovel = parseNovel,
	getPassage = getPassage,
	search = search,
	shrinkURL = shrinkURL,
	expandURL = expandURL
}
