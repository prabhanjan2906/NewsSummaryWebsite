from os import times

import trafilatura
from datetime import datetime, date

def fetchWebpageArticle(anOBJ):
  aURL = anOBJ['url']

  if 'publishedAt' not in anOBJ:
    anOBJ['publishedAt'] = date.today().strftime("%Y-%m-%d")
  else:
    timestamp = anOBJ['publishedAt']
    dt_object = datetime.fromisoformat(timestamp.replace('Z', '+00:00')).strftime('%Y-%m-%d')
    anOBJ['publishedAt'] = dt_object

  downloaded = trafilatura.fetch_url(aURL)
  if downloaded:
      anOBJ['text'] = trafilatura.extract(downloaded)
  else:
      # anOBJ['text'] = None
      return None
  return anOBJ

def getRequiredFormat(aggregate, aData):
  if not (aData == None):
    reqdObj = {}
    reqdObj.update(url=aData.get('url'),
                  title=aData.get('title'),
                  publishedAt=aData.get('publishedAt'),
                  text=aData.get('text')
                  )
    aggregate.append(reqdObj)
  return aggregate