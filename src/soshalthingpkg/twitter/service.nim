import karax/reactive, fetch, asyncjs, json, sequtils, options, tweet, article, tables
import ../service
from ../article as ba import ArticleData

type
    TimelinePayload = object
        posts: seq[Post]
        reposts: seq[Repost]
        quotes: seq[Quote]
        newArticles: seq[string]

proc parseTweets(tweets: JsonNode): TimelinePayload =
    for t in tweets:
        let parsed = parseTweet(t)

        if not result.posts.any(proc (p: Post): bool = p.id == parsed.post.id):
            result.posts.add(parsed.post)
        
        if parsed.repost.isSome:
            result.reposts.add(parsed.repost.get())
            result.newArticles.add(parsed.repost.get().id)
        elif parsed.quote.isSome:
            result.quotes.add(parsed.quote.get())
            result.newArticles.add(parsed.quote.get().id)
        else:
            result.newArticles.add(parsed.post.id)

proc handlePayload(tweets: JsonNode, articles: OrderedTableRef[string, ArticleData], timelineArticles: var RSeq[string], bottom = false) =
    let payload = if tweets.kind == JArray:
        parseTweets(tweets)
    else:
        parseTweets(tweets["statuses"])
    
    for p in payload.posts:
        articles[p.id] = p
    
    for r in payload.reposts:
        articles[r.id] = r
    
    for q in payload.quotes:
        articles[q.id] = q
    
    for i in payload.newArticles:
        timelineArticles.add(i)

proc getRefreshProc(endpoint: string): RefreshProc =
    let url = newURL(endpoint, "http://127.0.0.1:5000/")

    return proc(articles: OrderedTableRef[string, ArticleData], timelineArticles: var RSeq[string], bottom = false, options: TableRef[string, string]) {.async.} =
        let localUrl = newUrl(url)
        localUrl.searchParams.setParams(options)
        echo localUrl.toString()

        let tweets = await fetch(localUrl.toString()).toJsonNode()
        handlePayload(tweets, articles, timelineArticles, bottom)

let TwitterService* = newService(@[
    EndpointInfo(name: "Home Timeline", refresh: getRefreshProc("home_timeline")),
    EndpointInfo(name: "User Media", refresh: getRefreshProc("user_timeline")),
    EndpointInfo(name: "Search", refresh: getRefreshProc("search")),
    EndpointInfo(name: "List", refresh: getRefreshProc("list"))
])