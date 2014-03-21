logbot crawler
--------

Crawling
========

run the following to crawl all logbot.g0v.tw logs will be crawled into raw/ directory.

    lsc index.ls




Formatting
========

run the following to format raw data into more readable format:

    lsc format.ls


Searching with Formatted Output
========

run the following to search keyword in format.ls output:

    lsc format.ls > all-msg
    lsc search.ls your-keyword

