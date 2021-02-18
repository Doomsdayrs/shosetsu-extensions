-- {"id":74485,"ver":"1.0.1","libVer":"1.0.0","author":"TechnoJo4"}

local baseURL = "https://kobatochan.com"

local function shrinkURL(url)
	return url:gsub("^.-kobatochan%.com", "")
end

local function expandURL(url)
	return baseURL .. url
end

local function page(url, r)
	local doc = GETDocument(r and url or baseURL..url)
	local content = doc:selectFirst("#content article")
	local p = map(content:select("p"), function(v) return v:text() end)

	local page_block = content:selectFirst(".pgntn-page-pagination-block")
	if page_block then
		local p2 = page_block:children()
		local last = p2:get(p2:size()-1)
		if last:hasClass("post-page-numbers") then
			local next_page = page(last:attr("href"), true)
			local i = #p
			for j=1,#next_page do
				p[i+j] = next_page[j]
			end
		end
	end

	return r and p or table.concat(p, "\n")
end

return {
	id = 74485,
	name = "KobatoChanDaiSuki",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/src/main/resources/icons/KobatoChan.png",
	hasSearch = false,

	listings = {
		Listing("Novels", false, function(data)
			local doc = GETDocument(baseURL)
			return map(flatten(mapNotNil(doc:selectFirst("nav#access ul"):children(), function(v)
				local text = v:selectFirst("a"):text()
				return (text:find("Novels", 0, true) or text == "Original Works") and
						map(v:selectFirst("ul.sub-menu"):select("a"), function(v) return v end)
			end)), function(v)
				return Novel {
					title = v:text(),
					link = shrinkURL(v:attr("href"))
				}
			end)
		end)
	},

	getPassage = function(chapterURL)
		return page(chapterURL, false)
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(baseURL .. novelURL)
		local content = doc:selectFirst("#content article")

		local info = NovelInfo {
			title = content:selectFirst(".entry-title a"):text(),
			imageURL = content:selectFirst("img"):attr("src")
		}

		if loadChapters then
			info:setChapters(AsList(map(content:selectFirst(".entry-content"):select("a"), function(v, i)
				return NovelChapter {
					order = i,
					title = v:text(),
					link = shrinkURL(v:attr("href"))
				}
			end)))
		end

		return info
	end,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
