#!/usr/bin/python3

import feedparser

url = "https://www.wired.com/feed/category/science/latest/rss"
feed = feedparser.parse(url)

print(feed.feed.title, end =" ")

for entry in feed.entries:
    print(entry.title, end =" ")
    print(entry.summary, end =" ")
    print("|", end =" ")
quit