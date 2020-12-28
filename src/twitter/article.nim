import karax/[vdom, karaxdsl], tables, ../article, tweet

var datas* = initOrderedTable[string, Post]()

proc addArticle*(a: Post) = datas[a.id] = a

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
                            small: text "10m"
                    tdiv(class="tweet-paragraph"):
                        text data.text