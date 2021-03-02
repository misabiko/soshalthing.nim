import karax / [karax, karaxdsl, vdom, reactive], algorithm, times, asyncjs, strformat, tables
import service, article

type
    ArticlesContainer* = proc(self: var Timeline): VNode
    ToVNodeProc* = proc(t: Timeline, id: string): VNode
    Timeline* = ref object
        name*: string
        articles*: RSeq[string]
        service*: ServiceInfo
        toVNode: ToVNodeProc
        endpointIndex: int
        options*: TableRef[string, string]
        container*: ArticlesContainer
        lastBottomRefresh*, lastTopRefresh*: Time
        infiniteLoad*, loadingTop*, loadingBottom*: bool
        needTop*, needBottom*, showHidden*: RBool

let minRefreshDelay = initDuration(seconds = 1)

proc article*(self: Timeline, id: string): VNode = self.toVNode(self, id)

proc endpoint*(self: Timeline): EndpointInfo = self.service.endpoints[self.endpointIndex]

proc basicContainer(self: var Timeline): VNode =
    vmap(self.articles, tdiv(class="timelineArticles"), self.article)

proc basicSortedContainer*(self: var Timeline): VNode =
    var copy: seq[string]
    for i in 0..<len(self.articles):
        copy.add(self.articles[i])
    copy.sort(proc(x, y: string): int = cmp(self.service.articles[y].creationTime, self.service.articles[x].creationTime))
    result = buildHtml(tdiv(class="timelineArticles")):
        for i in copy:
            self.article i

proc isRefreshingTooFast(self: Timeline, bottom: bool, now = getTime()): bool =
    if bottom:
        if now - self.lastBottomRefresh < minRefreshDelay:
            return true
    else:
        if now - self.lastTopRefresh < minRefreshDelay:
            return true
    
    false

proc updateTime(self: Timeline, bottom: bool, now = getTime()) =
    if bottom:
        self.lastBottomRefresh = now
    else:
        self.lastTopRefresh = now

proc refresh*(self: Timeline, bottom = true, ignoreTime = false) {.async.} =
    if not self.endpoint.isReady():
        echo self.name & "'s endpoint is over limit."
        return

    let now = getTime()
    if not ignoreTime and self.isRefreshingTooFast(bottom, now):
        return
    self.updateTime(bottom, now)

    var a = self.articles
    await self.endpoint.refresh(self.service.articles, a, bottom, self.options)
    redraw()

    self.updateTime(bottom)
    let direction = if bottom:
        "bottom"
    else:
        "top"
    echo &"Refreshed {self.name} {direction} - {$a.len} articles"

proc refillTop*(self: var Timeline) {.async.} =
    if self.loadingTop:
        return
    
    self.loadingTop = true
    if not self.isRefreshingTooFast(false):
        echo &"Refilling {self.name} top"
        await self.refresh(false)
    self.loadingTop = false

proc refillBottom*(self: var Timeline) {.async.} =
    if self.loadingBottom:
        return
    
    self.loadingBottom = true
    if not self.isRefreshingTooFast(true):
        echo &"Refilling {self.name} bottom"
        await self.refresh()
    self.loadingBottom = false

proc newTimeline*(
        name: string,
        service: ServiceInfo,
        endpointIndex: int,
        toVNode: ToVNodeProc,
        container: ArticlesContainer = basicContainer,
        options = newTable[string, string](),
        infiniteLoad = false,
    ): Timeline =
    let now = getTime()
    result = Timeline(
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
    )

    discard result.refresh(ignoreTime = true)

proc headerButtons*(self: var Timeline): seq[VNode] =
    result.add do:
        buildHtml(button(class="infiniteTimeline")):
            span(class="icon"):
                italic(class="fas fa-lg fa-infinity")

            proc onclick() = self.infiniteLoad = not self.infiniteLoad

    result.add do:
        buildHtml(button(class="refreshTimeline")):
            span(class="icon"):
                italic(class="fas fa-lg fa-sync-alt")

            proc onclick() = discard self.refresh(ignoreTime = true)
    
    result.add do:
        buildHtml(button(class="openTimelineOptions")):
            span(class="icon"):
                italic(class="fas fa-lg fa-ellipsis-v")

proc timeline*(self: var Timeline, class = "timeline", hButtons = headerButtons(self)): VNode =
    var headerClass = "timelineHeader"
    if not self.endpoint.isReady():
        headerClass &= " timelineInvalid"

    buildHtml(section(class = class)):
        tdiv(class = headerClass):
            strong: text self.name

            tdiv(class="timelineButtons"):
                for b in hButtons:
                    b
        
        self.container(self)

# TODO Clicking head button move individually
# TODO Consider using StringTable for options