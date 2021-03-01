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
        infiniteLoad*: bool
        needTop*, needBottom*, loadingTop*, loadingBottom*: bool

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

proc refresh*(self: Timeline, bottom = true) {.async.} =
    if not self.endpoint.isReady():
        echo self.name & "'s endpoint is over limit."
        return

    var a = self.articles
    await self.endpoint.refresh(self.service.articles, a, bottom, self.options)
    redraw()
    let direction = if bottom:
        "bottom"
    else:
        "top"
    echo &"Refreshed {self.name} {direction} - {$a.len} articles"

proc refillTop*(self: var Timeline) {.async.} =
    if self.loadingTop:
        return
    
    self.loadingTop = true
    echo &"Refilling {self.name} top"
    await self.refresh(false)
    self.loadingTop = false

proc refillBottom*(self: var Timeline) {.async.} =
    if self.loadingBottom:
        return
    
    self.loadingBottom = true
    echo &"Refilling {self.name} bottom"
    await self.refresh()
    self.loadingBottom = false

proc newTimeline*(
        name: string,
        service: ServiceInfo,
        endpointIndex: int,
        toVNode: ToVNodeProc,
        container: ArticlesContainer = basicContainer,
        options = newTable[string, string]()
    ): Timeline =
    result = Timeline(
        name: name,
        articles: newRSeq[string](),
        service: service,
        endpointIndex: endpointIndex,
        toVNode: toVNode,
        options: options,
        container: container,
        needTop: true
    )
    discard result.refresh()

proc headerButtons*(self: var Timeline): seq[VNode] =
    result.add do:
        buildHtml(button(class="refreshTimeline")):
            span(class="icon"):
                italic(class="fas fa-lg fa-sync-alt")

            proc onclick() = discard self.refresh()
    
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