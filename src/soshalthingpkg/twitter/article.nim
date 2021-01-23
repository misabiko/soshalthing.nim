import karax/[karax, vdom, karaxdsl], tables, times, asyncjs, json
import ../article, tweet, fetch

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

proc printTweet(id: string) {.async.} =
    let tweet = await fetch("http://127.0.0.1:5000/status/" & id).toJsonNode()
    echo tweet

proc buttons(post: Post): VNode =
    result = buildHtml(nav(class="level is-mobile")):
        tdiv(class="level-left"):
            a(class = "level-item articleButton repostButton"):
                span(class = "icon"):
                    italic(class="fas fa-retweet")
                span: text $post.repostCount
            a(class = "level-item articleButton likeButton"):
                span(class = "icon"):
                    italic(class="far fa-heart")
                span: text $post.likeCount
            #if articlehasimages:
            #    a(class = "level-item articleButton compactOverrideButton"):
            #        span(class = "icon"):
            #            italic(class="fas fa-expand")
            a(class = "level-item articleButton articleMenuButton"):
                proc onclick() =
                    echo "menuclick!"
                    discard printTweet(post.id)
                span(class = "icon"):
                    italic(class="fas fa-ellipsis-h")

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
                buttons(data)
        tdiv(class = "postImages postMedia"):
            for i in data.images:
                tdiv(class = "mediaHolder"):
                    tdiv(class = "is-hidden imgPlaceholder")
                    img(src = i.url)

#TODO Make tweet buttons button elements