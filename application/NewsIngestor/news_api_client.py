import sys

from newsapi import NewsApiClient
from defines import *

@injectAPIKEYToClass
class NewsApiClientExtended(NewsApiClient):
    pass

client = NewsApiClientExtended()