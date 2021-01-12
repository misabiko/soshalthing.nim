import karax/[vdom, karaxdsl], tables, times
import ../article, tweet

var datas* = initOrderedTable[string, Post]()

proc addArticle*(a: Post) = datas[a.id] = a

proc toTimestampStr(dt: DateTime): string =
    let n = now()
    let interval = between(dt, now())
    let parts = interval.toParts
    if n.year != dt.year:
        return dt.format("d MMM YYYY")
    if parts[Days] > 0:
        return $parts[Days] & "d"
    if parts[Hours] > 0:
        return $parts[Hours] & "h"
    if parts[Minutes] > 0:
        return $parts[Minutes] & "m"
    if parts[Seconds] > 0:
        return $parts[Seconds] & "s"

proc toVNode*(id: string): VNode =
    let data = datas[id]
    result = buildHtml(article(class = "article")):
        tdiv(class = "media"):
            figure(class="media-left"):
                p(class="image is-64x64"):
                    img(alt=data.authorHandle & "'s avatar", src=data.authorAvatar)
            tdiv(class="media-content"):
                tdiv(class="content"):
                    tdiv(class="articleHeader"):
                        a(class="names"):
                            strong: text data.authorName
                            small: text "@" & data.authorHandle
                        span(class="timestamp"):
                            small: text data.creationTime.toTimestampStr
                    tdiv(class="tweet-paragraph"):
                        text data.text
        tdiv(class = "postImages"):
            for i in data.images:
                tdiv(class = "mediaHolder"):
                    tdiv(class = "is-hidden imgPlaceholder")
                    img(src = i.url)
