import karax / [karax, karaxdsl, vdom, reactive], algorithm, times, asyncjs, strformat, tables, options
import timeline, ../article, ../service

type PagedTimeline* = ref object of Timeline
        loadedPages*: seq[int]

# TODO Overload Timeline constructor
proc newPagedTimeline*(
        name: string,
        service: ServiceInfo,
        endpointIndex: int,
        toVNode: ToVNodeProc,
        container: ArticlesContainer = basicContainer(),
        options = newTable[string, string](),
        infiniteLoad = false,
        startPage = 0,
    ): PagedTimeline =
    let now = getTime()
    result = PagedTimeline(
        name: name,
        articles: newRSeq[string](),
        service: service,
        endpointIndex: endpointIndex,
        toVNode: toVNode,
        options: options,
        container: container,
        infiniteLoad: infiniteLoad,
        lastBottomRefresh: now,
        needTop: RBool(value: true),
        needBottom: RBool(value: false),
        showHidden: RBool(value: false),
        showOptions: RBool(value: false),
        modalId: "".rstr
    )
    service.endpoints[endpointIndex].subscribers.add(result.articles)

    result.settings.add(articleClickSetting)

    discard result.refresh(ignoreTime = true)

proc getNextTopPage*(loadedPages: seq[int]): Option[int] =
    if loadedPages[0] == 0:
        return none(int)
    else:
        return some(loadedPages[0] - 1)

#TODO Get current page and find first unloaded page from there
proc getNextBottomPage*(loadedPages: seq[int]): Option[int] =
    some(loadedPages[loadedPages.len - 1] + 1)

proc getNextPage*(t: PagedTimeline, bottom: bool): Option[int] =
    if t.loadedPages.len == 0:
        return some(0)
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

    let pageNum = self.getNextPage(bottom)
    if pageNum.isNone:
        return
    
    await self.service.refreshEndpoint(self.endpointIndex, bottom, self.options, pageNum.get())
    self.loadedPages.add(pageNum.get())

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