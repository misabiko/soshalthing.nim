import karax/[karax, vdom, karaxdsl], tables, times, asyncjs, json, options
import ../article, ../timeline, tweet, fetch

proc toTimestampStr(dt: DateTime): string =
    if not dt.isInitialized:
        return "sometime"

    let n = now()
    let interval = between(dt, n)
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

proc articleHeader(post: Post): VNode =
    buildHtml(tdiv(class="articleHeader")):
        a(class="names"):
            strong: text post.authorName
            small: text "@" & post.authorHandle
        span(class="timestamp"):
            small: text post.creationTime.toTimestampStr

proc articleSkeleton(post: Post, superHeader: Option[VNode], extra: Option[VNode], footer: Option[VNode]): VNode =
    return buildHtml(article(class = "article")):
        if superHeader.isSome: superHeader.get()

        tdiv(class = "media"):
            figure(class="media-left"):
                p(class="image is-64x64"):
                    img(alt=post.authorHandle & "'s avatar", src=post.authorAvatar)
            tdiv(class="media-content"):
                tdiv(class="content"):
                    articleHeader(post)
                    tdiv(class="tweet-paragraph"):
                        text post.text
                if extra.isSome: extra.get()
                buttons(post)
        if footer.isSome: footer.get()

method getSuperHeader(data: ArticleData): Option[VNode] {.base.} = none(VNode)

method getSuperHeader(repost: Repost): Option[VNode] =
    let href = "https://twitter.com/" & repost.reposterHandle
    return some do:
        buildHtml(tdiv(class = "repostLabel")):
            a(href=href, target="_blank", rel="noopener noreferrer"):
                text repost.reposterName & " retweeted"

proc articleMedia(post: Post): VNode =
    return buildHtml(tdiv(class = "postImages postMedia")):
        for i in post.images:
            tdiv(class = "mediaHolder"):
                tdiv(class = "is-hidden imgPlaceholder")
                img(src = i.url)

method getQuotedPost(articles: OrderedTableRef[string, ArticleData], data: ArticleData): Option[VNode] {.base.} = none(VNode)

method getQuotedPost(articles: OrderedTableRef[string, ArticleData], quote: Quote): Option[VNode] =
    let post = articles[quote.quotedId].Post
    return some do:
        buildHtml(tdiv(class = "quotedPost")):
            articleHeader(post)
            tdiv(class="tweet-paragraph"):
                text post.text
            articleMedia(post)


proc toVNode*(t: Timeline, id: string): VNode =
    let data = t.service.articles[id]
    let actualPost = if data of Repost:
        t.service.articles[Repost(data).repostedId].Post
    else:
        data.Post

    let footer = some(articleMedia(actualPost))

    let extra = t.service.articles.getQuotedPost(data)

    return articleSkeleton(actualPost, data.getSuperHeader(), extra, footer)

#TODO Make tweet buttons button elements