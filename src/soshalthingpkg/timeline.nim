import karax / [karax, karaxdsl, vdom, reactive], algorithm, times, asyncjs, strformat
import service

type
    ArticlesContainer* = proc(self: var Timeline): VNode
    Timeline* = object
        name*: string
        articles*: RSeq[string]
        service*: ServiceInfo
        container*: ArticlesContainer
        infiniteLoad*: bool
        needTop*, needBottom*, loadingTop*, loadingBottom*: bool

proc article(self: Timeline, id: string): VNode = self.service.toVNode(id)

proc basicContainer(self: var Timeline): VNode =
    vmap(self.articles, tdiv(class="timelineArticles"), self.article)

proc basicSortedContainer*(self: var Timeline): VNode =
    var copy: seq[string]
    for i in 0..<len(self.articles):
        copy.add(self.articles[i])
    copy.sort(proc(x, y: string): int = cmp(self.service.getData(y).creationTime, self.service.getData(x).creationTime))
    result = buildHtml(tdiv(class="timelineArticles")):
        for i in copy:
            self.article i

proc refresh*(self: Timeline, bottom = true) {.async.} =
    var a = self.articles
    await self.service.refresh(a, bottom)
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

proc newTimeline*(name: string, service: ServiceInfo, container: ArticlesContainer = basicContainer): Timeline =
    result = Timeline(name: name, articles: newRSeq[string](), service: service, container: container, needTop: true)
    discard result.refresh()

proc timeline*(self: var Timeline, class = "timeline"): VNode =
    result = buildHtml(section(class = class)):
        tdiv(class = "timelineHeader"):
            strong: text self.name

            tdiv(class="timelineButtons"):
                button(class="refreshTimeline"):
                    span(class="icon"):
                        italic(class="fas fa-lg fa-sync-alt")

                    proc onclick() = discard self.refresh()
                button(class="openTimelineOptions"):
                    span(class="icon"):
                        italic(class="fas fa-lg fa-ellipsis-v")
        
        self.container(self)

# TODO Clicking head button move individually