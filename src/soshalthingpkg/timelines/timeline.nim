import karax / [karax, karaxdsl, vdom, reactive], algorithm, times, asyncjs, strformat, tables
import ../service, ../article

type
    TimelineProc* = proc(t: Timeline): VNode
    ArticlesContainer* = ref object of RootObj
        toVNode*: proc(self: ArticlesContainer, t: var Timeline): VNode
    ToVNodeProc* = proc(t: Timeline, id: string): VNode
    Timeline* = ref object of RootObj
        name*: string
        articles*: RSeq[string]
        service*: ServiceInfo
        toVNode*: ToVNodeProc
        endpointIndex*: int
        options*: TableRef[string, string]
        container*: ArticlesContainer
        lastBottomRefresh*, lastTopRefresh*: Time
        infiniteLoad*, loadingTop*, loadingBottom*: bool
        needTop*, needBottom*, showHidden*, showOptions*: RBool
        settings*: seq[TimelineProc]

let minRefreshDelay = initDuration(seconds = 1)

proc article*(self: Timeline, id: string): VNode = self.toVNode(self, id)

proc endpoint*(self: Timeline): EndpointInfo = self.service.endpoints[self.endpointIndex]

proc basicContainer*(): ArticlesContainer =
    let toVNode = proc(self: ArticlesContainer, t: var Timeline): VNode =
        vmap(t.articles, tdiv(class="timelineArticles"), t.article)

    ArticlesContainer(toVNode: toVNode)

proc basicSortedContainer*(): ArticlesContainer =
    let toVNode = proc(self: ArticlesContainer, t: var Timeline): VNode =
        var copy: seq[string]
        for i in 0..<len(t.articles):
            copy.add(t.articles[i])
        copy.sort(proc(x, y: string): int = cmp(t.service.articles[y].creationTime, t.service.articles[x].creationTime))
        result = buildHtml(tdiv(class="timelineArticles")):
            for i in copy:
                t.article i

    ArticlesContainer(toVNode: toVNode)

proc isRefreshingTooFast*(self: Timeline, bottom: bool, now = getTime()): bool =
    if bottom:
        if now - self.lastBottomRefresh < minRefreshDelay:
            return true
    else:
        if now - self.lastTopRefresh < minRefreshDelay:
            return true
    
    false

proc updateTime*(self: Timeline, bottom: bool, now = getTime()) =
    if bottom:
        self.lastBottomRefresh = now
    else:
        self.lastTopRefresh = now

method refresh*(self: Timeline, bottom = true, ignoreTime = false) {.async, base.} =
    if not self.endpoint.isReady():
        echo self.name & "'s endpoint is over limit."
        return

    let now = getTime()
    if not ignoreTime and self.isRefreshingTooFast(bottom, now):
        return
    self.updateTime(bottom, now)

    await self.service.refreshEndpoint(self.endpointIndex, bottom, self.options)

    self.updateTime(bottom)
    let direction = if bottom:
        "bottom"
    else:
        "top"

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
        container: ArticlesContainer = basicContainer(),
        options = newTable[string, string](),
        infiniteLoad = false
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
        showOptions: RBool(value: false)
    )
    service.endpoints[endpointIndex].subscribers.add(result.articles)

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

            proc onclick() = self.showOptions <- not self.showOptions.value

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
        
        if self.showOptions.value:
            tdiv(class = "timelineOptions"):
                for settingProc in self.settings:
                    self.settingProc()

        self.container.toVNode(self.container, self)

# TODO Clicking head button move individually
# TODO Consider using StringTable for options