import karax / [karax, karaxdsl, vdom, reactive], service

type
    Timeline* = object
        name*: string
        articles*: RSeq[string]
        service*: ServiceInfo

proc newTimeline*(name: string, service: ServiceInfo): Timeline =
    result = Timeline(name: name, service: service)
    result.articles = newRSeq[string]()

proc article(self: Timeline, id: string): VNode = self.service.toVNode(id)

proc refresh*(self: Timeline) =
    var a = self.articles
    discard self.service.refresh(a)

proc timeline*(self: Timeline): VNode =
    result = buildHtml(tdiv(class = "timeline")):
        tdiv(class = "timelineHeader"):
            strong: text self.name

            tdiv(class="timelineButtons"):
                button(class="refreshTimeline"):
                    span(class="icon"):
                        italic(class="fas fa-lg fa-sync-alt")
                button(class="openTimelineOptions"):
                    span(class="icon"):
                        italic(class="fas fa-lg fa-ellipsis-v")
        
        vmap(self.articles, tdiv(class="timelineArticles"), self.article)