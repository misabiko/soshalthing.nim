import json, options, times, sequtils
import ../article

type
    Post* = object of ArticleData
        authorName*: string
        authorHandle*: string
        authorAvatar*: string
        text*: string
        images*: seq[PostImageData]
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
    #ImageSize = object
    #    w, h: int
    #    resize: string
    PostImageData* = object
        url*: string
        sizes*: JsonNode
        indices*: tuple[first: int, second: int]
    PostVideoData = object
    Entities = object
        images: seq[PostImageData]
        video: PostVideoData
        #userMentions : UserMentionData[]
        #hashtags : HashtagData[]
        #externalLinks : ExternalLinkData[]

#Tue Aug 18 00:00:00 +0000 2020
const tweetTimeFormat = initTimeFormat("ddd MMM dd HH:mm:ss zz'00' YYYY")

proc newImageData(media: JsonNode): PostImageData =
    result.url = media["media_url_https"].str
    result.sizes = media["sizes"]
    let rawIndices = media["indices"]
    result.indices = (first: rawIndices[0].num.int, second: rawIndices[1].num.int)

proc parseEntities(tweet: JsonNode): Entities =
    if tweet.hasKey("extended_entities"):
        let medias = tweet["extended_entities"]{"media"}

        if medias != nil:
            case medias[0]["type"].str:
                of "photo":
                    result.images = medias.getElems().map newImageData
                        
    elif tweet.hasKey("entities") and tweet["entities"].hasKey("media"):
        result.images = @[tweet["entities"]["media"][0].newImageData]

proc getText(tweet: JsonNode): string =
    if tweet.hasKey("full_text"):
        tweet["full_text"].str
    else:
        tweet["text"].str

proc toPost(tweet: JsonNode): Post =
    let user = tweet["user"]
    let entities = tweet.parseEntities()

    result = Post(
        id: tweet["id_str"].str,
        creationTime: tweet["created_at"].str.parse(tweetTimeFormat),
        authorName: user["name"].str,
        authorHandle: user["screen_name"].str,
        authorAvatar: user["profile_image_url_https"].str,
        text: tweet.getText(),
        images: entities.images,
        #video,
        liked: tweet["favorited"].bval,
        reposted: tweet["retweeted"].bval,
        likeCount: tweet["favorite_count"].num.int,
        repostCount: tweet["retweet_count"].num.int,
        #userMentions,
        #hashtags,
        #externalLinks,
        #rawObject: tweet,
    )

proc toRepost(tweet: JsonNode): Repost =
    let user = tweet["user"]

    result = Repost(
        id: tweet["id_str"].str,
        creationTime: tweet["created_at"].str.parse(tweetTimeFormat),
        repostedId: tweet["retweeted_status"]["id_str"].str,
        reposterName: user["name"].str,
        reposterHandle: user["screen_name"].str,
        reposterAvatar: user["profile_image_url_https"].str,
    )

proc toQuote(tweet: JsonNode): Quote =
    let user = tweet["user"]

    result = Quote(
        id: tweet["id_str"].str,
        creationTime: tweet["created_at"].str.parse(tweetTimeFormat),
        authorName: user["name"].str,
        authorHandle: user["screen_name"].str,
        authorAvatar: user["profile_image_url_https"].str,
        text: tweet.getText(),
        #images,
        #video,
        liked: tweet["favorited"].bval,
        reposted: tweet["retweeted"].bval,
        likeCount: tweet["favorite_count"].num.int,
        repostCount: tweet["retweet_count"].num.int,
        #userMentions,
        #hashtags,
        #externalLinks,
        quotedId: tweet["quoted_status"]["id_str"].str,
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