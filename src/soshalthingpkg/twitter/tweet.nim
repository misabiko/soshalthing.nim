import json, options, times, ../article

type
    Post* = object of ArticleData
        authorName*: string
        authorHandle*: string
        authorAvatar*: string
        text*: string
        #images*: PostImageData[] #Nullable
        #video*: PostVideoData #Nullable
        liked*: bool
        reposted*: bool
        likeCount*: int
        repostCount*: int
        #userMentions?*: UserMentionData[]
        #hashtags?*: HashtagData[]
        #externalLinks?*: ExternalLinkData[]
    Repost* = object of ArticleData
        repostedId*: string
        reposterName*: string
        reposterHandle*: string
        reposterAvatar*: string
    Quote* = object of Post
        quotedId*: string

#Tue Aug 18 00:00:00 +0000 2020
const tweetTimeFormat = initTimeFormat("ddd MMM dd HH:mm:ss zz'00' YYYY")

proc toPost(tweet: JsonNode): Post =
    let user = tweet["user"]

    result = Post(
        id: tweet["id_str"].getStr(),
        creationTime: tweet["created_at"].getStr().parse(tweetTimeFormat),
        authorName: user["name"].getStr(),
        authorHandle: user["screen_name"].getStr(),
        authorAvatar: user["profile_image_url_https"].getStr(),
        text: if tweet.hasKey("full_text"): tweet["full_text"].getStr() else: tweet["text"].getStr(),
        #images,
        #video,
        liked: tweet["favorited"].getBool(),
        reposted: tweet["retweeted"].getBool(),
        likeCount: tweet["favorite_count"].getInt(),
        repostCount: tweet["retweet_count"].getInt(),
        #userMentions,
        #hashtags,
        #externalLinks,
        #rawObject: tweet,
    )

proc toRepost(tweet: JsonNode): Repost =
    let user = tweet["user"]

    result = Repost(
        id: tweet["id_str"].getStr(),
        creationTime: tweet["created_at"].getStr().parse(tweetTimeFormat),
        repostedId: tweet["retweeted_status"]["id_str"].getStr(),
        reposterName: user["name"].getStr(),
        reposterHandle: user["screen_name"].getStr(),
        reposterAvatar: user["profile_image_url_https"].getStr(),
    )

proc toQuote(tweet: JsonNode): Quote =
    let user = tweet["user"]

    result = Quote(
        id: tweet["id_str"].getStr(),
        creationTime: tweet["created_at"].getStr().parse(tweetTimeFormat),
        authorName: user["name"].getStr(),
        authorHandle: user["screen_name"].getStr(),
        authorAvatar: user["profile_image_url_https"].getStr(),
        text: tweet["text"].getStr(),
        #images,
        #video,
        liked: tweet["favorited"].getBool(),
        reposted: tweet["retweeted"].getBool(),
        likeCount: tweet["favorite_count"].getInt(),
        repostCount: tweet["retweet_count"].getInt(),
        #userMentions,
        #hashtags,
        #externalLinks,
        quotedId: tweet["quoted_status"]["id_str"].getStr(),
    )

proc parseTweet*(tweet: JsonNode): tuple[post: Post, repost: Option[Repost], quote: Option[Quote]] =
    if tweet.hasKey("retweeted_status"):
        result = (
            tweet["retweeted_status"].toPost,
            some(tweet.toRepost),
            none(Quote)
        )
    elif tweet.hasKey("quoted_status"):
        result = (
            tweet["quoted_status"].toPost,
            none(Repost),
            some(tweet.toQuote)
        )
    else:
        result = (
            tweet.toPost,
            none(Repost),
            none(Quote)
        )