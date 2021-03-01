import karax/reactive, fetch, asyncjs, json, sequtils, options, tweet, tables
import ../service
from ../article as ba import ArticleData

type
    TimelinePayload = object
        posts: seq[Post]
        reposts: seq[Repost]
        quotes: seq[Quote]
        newArticles: seq[string]
    RateLimitInfo* = object
        limit*, remaining*, reset*: int

var rateLimits* = initTable[string, RateLimitInfo]()

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
    
    for id in payload.newArticles:
        if id notin timelineArticles:
            timelineArticles.add(id)

proc updatingRateLimits() {.async.} =
    let ratelimit = await fetch("http://127.0.0.1:5000/ratelimit").toJsonNode()
    
    for resType, rates in ratelimit["resources"].pairs:
        for endpoint, rate in rates.pairs:
            if endpoint in rateLimits:
                rateLimits[endpoint].limit = rate["limit"].num.int
                rateLimits[endpoint].remaining = rate["remaining"].num.int
                rateLimits[endpoint].reset = rate["reset"].num.int
    
    echo rateLimits["/statuses/home_timeline"]

proc getRefreshProc(endpoint: string): RefreshProc =
    let url = newURL(endpoint, "http://127.0.0.1:5000/")

    return proc(articles: OrderedTableRef[string, ArticleData], timelineArticles: var RSeq[string], bottom = false, options: TableRef[string, string]) {.async.} =
        let localUrl = newUrl(url)
        localUrl.searchParams.setParams(options)
        echo localUrl.toString()

        let tweets = await fetch(localUrl.toString()).toJsonNode()
        handlePayload(tweets, articles, timelineArticles, bottom)

        await updatingRateLimits()

proc newTwitterEndpoint(name, proxyEndpoint, fullEndpoint: string, limit, reset: int): EndpointInfo =
    result = EndpointInfo(name: name, refresh: proxyEndpoint.getRefreshProc())
    rateLimits[fullEndpoint] = RateLimitInfo(limit: limit, remaining: limit, reset: reset)

let TwitterService* = newService(@[
    newTwitterEndpoint("Home Timeline", "home_timeline", "/statuses/home_timeline", 15, 1614570897),
    newTwitterEndpoint("User Media", "user_timeline", "/statuses/user_timeline", 900, 1614570897),
    newTwitterEndpoint("Search", "search", "/search/tweets", 180, 1614570897),
    newTwitterEndpoint("List", "list", "/lists/statuses", 900, 1614570897),
])