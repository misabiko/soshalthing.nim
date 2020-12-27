import fetch, asyncjs, json, sequtils, options, tweet

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
        elif parsed.quote.isSome:
            result.quotes.add(parsed.quote.get())
        #else:

proc getHomeTimeline*() {.async.} =
    let tweets = await fetch("http://127.0.0.1:5000/home_timeline").toJsonNode()
    let payload = parseTweets(tweets)
    echo payload.posts[0].text