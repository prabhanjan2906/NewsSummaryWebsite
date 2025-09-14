import sys

from package.newsapi import NewsApiClient
from defines import *

@injectAPIKEYToClass
class NewsApiClientExtended(NewsApiClient):
    pass

client = NewsApiClientExtended()