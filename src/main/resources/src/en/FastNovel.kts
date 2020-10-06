import app.shosetsu.lib.*
import app.shosetsu.lib.kts.ShosetsuKtsLib
import org.json.JSONObject
object : IExtension {

	override val name: String = "FastNovel"
	override val baseURL: String = "https://fastnovel.net"
	override val imageURL: String = "https://fastnovel.net/skin/images/logo.png"
	override val formatterID: Int = 258
	override val hasSearch: Boolean = true
	override val isSearchIncrementing: Boolean = true
	override val hasCloudFlare: Boolean = false
	override val listings: Array<IExtension.Listing> = arrayOf()
	override val settingsModel: Array<Filter<*>> = arrayOf()
	override val searchFiltersModel: Array<Filter<*>> = arrayOf()
	override val chapterType: Novel.ChapterType = Novel.ChapterType.STRING

	private val latest = IExtension.Listing("Latest", true) { data ->
		return@Listing ShosetsuKtsLib.GETDocument(baseURL + "/list/latest.html?page=" + data[PAGE_INDEX])
				.selectFirst("ul.list-film").select("li.film-item").map {
					Novel.Listing().apply {
						val data = it.selectFirst("a")
						link = baseURL + data.attr("href")
						title = data.attr("title")
						imageURL = data.selectFirst("div.img").attr("data-original")
					}
				}.toTypedArray()
	}


	override val metaData: JSONObject by lazy { JSONObject() }

	override fun updateSetting(id: Int, value: Any?) {
	}

	override fun search(data: Map<Int, *>): Array<Novel.Listing> =
			ShosetsuKtsLib.GETDocument(baseURL + "/search/" + data[QUERY_INDEX]).select("ul.list-film").map {
				Novel.Listing().apply {
					val data = it.selectFirst("a")
					link = baseURL + data.attr("href")
					title = data.attr("title")
					imageURL = data.selectFirst("div.img").attr("data-original")
				}
			}.toTypedArray()

	override fun getPassage(chapterURL: String): String =
			ShosetsuKtsLib.GETDocument(chapterURL).select("div.box-player")
					.select("p").map { it.text() }.joinToString("\n")


	override fun parseNovel(novelURL: String, loadChapters: Boolean): Novel.Info = Novel.Info().apply {
		val document = ShosetsuKtsLib.GETDocument(novelURL)
		imageURL = document.selectFirst("div.book-cover").attr("data-original")
		title = document.selectFirst("h1.name").text()
		description = document.select("div.film-content").select("p").map { it.text() }.joinToString("\n")
		val elements = document.selectFirst("ul.meta-data").select("li")
		authors = elements.get(0).select("a").map { it.text() }.toTypedArray()
		genres = elements.get(1).select("a").map { it.text() }.toTypedArray()
		status = if (elements.get(2).selectFirst("strong").text().contains("Completed"))
			Novel.Status.COMPLETED else Novel.Status.PUBLISHING

		var chaptrsIndex = 0.0
		val chapterList = ArrayList<Novel.Chapter>()
		document.selectFirst("div.block-film").select("div.book").forEach { element ->
			val volumeName = element.selectFirst("div.title").selectFirst("a.accordion-toggle").text()
			element.select("li").forEach { element2 ->
				chapterList.add(Novel.Chapter().apply {
					val data = element2.selectFirst("a.chapter")
					title = volumeName + " " + data.text()
					link = baseURL + data.attr("href")
					order = chaptrsIndex
					chaptrsIndex++
				})
			}
		}
		chapters = chapterList
	}

	override fun expandURL(smallURL: String, type: Int): String = baseURL + "/" + smallURL

	override fun shrinkURL(longURL: String, type: Int): String = longURL.replace(baseURL + "/", "")
}