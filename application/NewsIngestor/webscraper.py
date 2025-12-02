from os import times
import trafilatura
from datetime import datetime, date

def fetchWebpageArticle(aURL):
  downloaded = trafilatura.fetch_url(aURL)
  if downloaded:
      return trafilatura.extract(downloaded)
  else:
      # anOBJ['text'] = None
      return None

def getRequiredFormat(aData):
  if not (aData == None):
    reqdObj = {}
    reqdObj.update(url=aData.get('url'),
                  title=aData.get('title'),
                  publishedAt=aData.get('publishedAt'),
                  text=aData.get('text')
                  )
  return reqdObj