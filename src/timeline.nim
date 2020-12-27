include karax / prelude
import twitter/article

type
    Timeline* = object
        name*: string
        articles*: seq[string]

proc timeline*(self: Timeline): VNode =
    result = buildHtml(tdiv(class = "timeline")):
        tdiv(class = "timelineHeader"):
            strong: text self.name
        for i in self.articles:
            i.article()