import os

def injectDictionaryGeneral(func):
  def wrapper(*args, **kwargs):
    language = os.environ.get("NEWSAPI_LANGUAGE")
    # language = os.environ.get("language")
    language = "en"
    pageSize = 100
    kwargs.update(
        language=language,
        page_size=pageSize
    )
    return func(*args, **kwargs)
  return wrapper

def injectHeadLinesSpecific(func):
  def wrapper(*args, **kwargs):
    country = os.environ.get("NEWSAPI_COUNTRY")
    sortBy = "publishedAt"
    kwargs.update(
      category=set(["business", "entertainment", "general", "health", "science", "sports", "technology"]),
      country=country,
      sortBy=sortBy
      )
    return func(*args, **kwargs)
  return wrapper

def injectAPIKEY(func):
  def wrapper(*args, **kwargs):
    NEWS_API_KEY = os.environ.get("NEWS_API_KEY")
    return func(NEWS_API_KEY, *args, **kwargs)
  return wrapper

def injectAPIKEYToClass(cls):
  @injectAPIKEY
  def wrapper(apiKey, *args, **kwargs):
    return cls(apiKey, *args, **kwargs)
  return wrapper
