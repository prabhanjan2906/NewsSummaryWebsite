from news_api_client import client
from defines import injectDictionaryGeneral

@injectDictionaryGeneral
def getNews(q=None, *args, **kwargs):
    try:
        articles = []
        if q is None:
            articles = client.get_top_headlines(*args, **kwargs)
        else:
            articles = client.get_everything(q,*args, **kwargs)
        return articles['articles']
    except Exception as e:
        print(f"Error fetching articles: {e}")
        return None