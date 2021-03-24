import karax/[kdom], fetch, asyncjs, json, sequtils, options, tweet, tables, strtabs, logging
import ../service
from ../article as ba import ArticleData, ArticleCollection

type
    RateLimitInfo* = object
        limit*, remaining*, reset*: int
    TwitterEndpointInfo* = ref object of EndpointInfo
        fullEndpoint: string

var rateLimits* = initTable[string, RateLimitInfo]()

proc parseTweets(tweets: JsonNode): EndpointPayload =
    for t in tweets:
        let parsed = parseTweet(t)

        if not result.articles.any(proc (p: Post): bool = p.id == parsed.post.id):
            result.articles.add(parsed.post)
        
        if parsed.repost.isSome:
            result.articles.add(parsed.repost.get())
            result.newArticles.add(parsed.repost.get().id)
        elif parsed.quote.isSome:
            result.articles.add(parsed.quote.get())
            result.newArticles.add(parsed.quote.get().id)
        else:
            result.newArticles.add(parsed.post.id)

proc handlePayload(tweets: JsonNode, bottom = false): EndpointPayload =
    if tweets.kind == JArray:
        parseTweets(tweets)
    else:
        parseTweets(tweets["statuses"])

proc retweetFilter*(a: ArticleData): bool =
    not (a of Repost)

proc mediaFilter*(a: ArticleData): bool =
    Post(a).images.len > 0

proc updatingRateLimits() {.async.} =
    let ratelimit = await fetch("http://127.0.0.1:5000/ratelimit").toJsonNode()
    
    for resType, rates in ratelimit["resources"].pairs:
        for endpoint, rate in rates.pairs:
            if endpoint in rateLimits:
                rateLimits[endpoint].limit = rate["limit"].num.int
                rateLimits[endpoint].remaining = rate["remaining"].num.int
                rateLimits[endpoint].reset = rate["reset"].num.int
    
    debug "Refreshed rate limits..."

proc getRefreshProc(endpoint, fullEndpoint: string): RefreshProc =
    let url = newURL(endpoint, "http://127.0.0.1:5000/")

    return proc(bottom = false, options: RefreshOptions): Future[EndpointPayload] {.async.} =
        let localUrl = newUrl(url)
        localUrl.searchParams.setParams(options["options"].StringTableRef)

        let tweets = await fetch(localUrl.toString()).toJsonNode()
        let payload = handlePayload(tweets, bottom)

        rateLimits[fullEndpoint].remaining.dec

        return payload

proc endpointIsReady(fullEndpoint: string): proc(): bool =
    return proc(): bool =
        rateLimits[fullEndpoint].remaining > 0

proc newTwitterEndpoint(name, proxyEndpoint, fullEndpoint: string, limit, reset: int): EndpointInfo =
    result = TwitterEndpointInfo(
        name: name,
        refreshProc: proxyEndpoint.getRefreshProc(fullEndpoint),
        isReady: fullEndpoint.endpointIsReady(),
        fullEndpoint: fullEndpoint,
    )

    rateLimits[fullEndpoint] = RateLimitInfo(limit: limit, remaining: limit, reset: reset)

let rateLimitInterval = window.setInterval(proc() = discard updatingRateLimits(), 60000)

addService("Twitter", newService(@[
    newTwitterEndpoint("Home Timeline", "home_timeline", "/statuses/home_timeline", 15, 1614570897),
    newTwitterEndpoint("User Media", "user_timeline", "/statuses/user_timeline", 900, 1614570897),
    newTwitterEndpoint("Search", "search", "/search/tweets", 180, 1614570897),
    newTwitterEndpoint("List", "list", "/lists/statuses", 900, 1614570897),
]))