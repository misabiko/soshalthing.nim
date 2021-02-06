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

proc handlePayload(tweets: JsonNode, articles: var RSeq[string], bottom = false) =
    let payload = parseTweets(tweets)
    for p in payload.posts:
        p.addArticle()
    
    for r in payload.reposts:
        r.addArticle()
    
    for q in payload.quotes:
        q.addArticle()
    
    for i in payload.newArticles:
        articles.add(i)

proc getHomeTimeline*(articles: var RSeq[string], bottom = false) {.async.} =
    let tweets = await fetch("http://127.0.0.1:5000/home_timeline").toJsonNode()
    handlePayload(tweets, articles, bottom)

proc getUserMedia*(articles: var RSeq[string], bottom = false) {.async.} =
    let tweets = await fetch("http://127.0.0.1:5000/user_timeline").toJsonNode()
    handlePayload(tweets, articles, bottom)

proc getData(id: string): ArticleData = datas[id]

let TwitterService* = ServiceInfo(toVNode: article.toVNode, getData: getData, refresh: getHomeTimeline)
let TwitterService2* = ServiceInfo(toVNode: article.toVNode, getData: getData, refresh: getUserMedia)