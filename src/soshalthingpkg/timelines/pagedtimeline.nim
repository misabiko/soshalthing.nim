import karax / [karax, karaxdsl, vdom, reactive], algorithm, times, asyncjs, strformat, tables, options, strtabs
import timeline, ../article, ../service

type
    PageNum* = ref object of RootObj
        value*: int
    PagedTimeline* = ref object of Timeline
        loadedPages*: seq[int]

proc newPageNum(value: int): PageNum =
    result = new(PageNum)
    result.value = value

proc newPagedTimeline*(
        name: string,
        serviceName: string,
        endpointIndex: int,
        toVNode, toModal: ToVNodeProc,
        container: ArticlesContainer = basicContainer(),
        options = newStringTable(),
        infiniteLoad = false,
        articleFilter = proc(a: ArticleData): bool = true,
        interval = 0,
        baseOptions = RefreshOptions(),
        startPage = 0,
    ): PagedTimeline =
    #[result = newTimeline(
        name, serviceName,
        endpointIndex,
        toVNode,
        toModal,
        container,
        options,
        infiniteLoad,
        articleFilter,
        0,
        baseOptions,
    ).PagedTimeline]#
    let now = getTime()
    result = PagedTimeline(
        name: name,
        articles: newRSeq[string](),
        serviceName: serviceName,
        endpointIndex: endpointIndex,
        toVNode: toVNode,
        toModal: toModal,
        options: options,
        container: container,
        infiniteLoad: infiniteLoad,
        lastBottomRefresh: now,
        needTop: RBool(value: true),
        needBottom: RBool(value: false),
        showHidden: RBool(value: false),
        showOptions: RBool(value: false),
        modalId: "".rstr,
        articleFilter: articleFilter,
        baseOptions: baseOptions,
    )
    result.service.endpoints[endpointIndex].subscribers.add(result.articles)

    result.settings.add(articleClickSetting)
    result.settings.add(infiniteLoadSetting)

proc getNextTopPage*(loadedPages: seq[int]): Option[PageNum] =
    if loadedPages[0] == 0:
        return none(PageNum)
    else:
        return newPageNum(loadedPages[0] - 1).some

#TODO Get current page and find first unloaded page from there
proc getNextBottomPage*(loadedPages: seq[int]): Option[PageNum] =
    newPageNum(loadedPages[loadedPages.len - 1] + 1).some

proc getNextPage*(t: PagedTimeline, bottom: bool): Option[PageNum] =
    if t.loadedPages.len == 0:
        return newPageNum(0).some
    elif bottom:
        t.loadedPages.getNextBottomPage()
    else:
        t.loadedPages.getNextTopPage()

method refresh*(self: PagedTimeline, bottom = true, ignoreTime = false) {.async.} =
    if not self.endpoint.isReady():
        echo self.name & "'s endpoint is over limit."
        return

    let now = getTime()
    if not ignoreTime and self.isRefreshingTooFast(bottom, now):
        return
    self.updateTime(bottom, now)

    echo "paged refresh"
    let pageNum = self.getNextPage(bottom)
    if pageNum.isNone:
        return
    
    var refreshOptions: RefreshOptions
    for k, v in self.baseOptions.pairs:
        refreshOptions[k] = v
    refreshOptions["options"] = self.options
    refreshOptions["pageNum"] = pageNum.get()

    await self.service.refreshEndpoint(self.endpointIndex, bottom, refreshOptions)
    self.loadedPages.add(pageNum.get().value)

    self.updateTime(bottom)
    let direction = if bottom:
        "bottom"
    else:
        "top"

when isMainModule:
    assert @[].getNextBottomPage() == some(0)
    assert @[].getNextTopPage() == none(int)
    assert @[0, 1, 2].getNextBottomPage() == some(3)
    assert @[0, 1, 3, 5, 8].getNextBottomPage() == some(9)
    assert @[0, 1, 3, 5, 8, 9].getNextTopPage() == none(int)
