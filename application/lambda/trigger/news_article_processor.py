import bedrock_config

TASK_PROMPT = """
You are a professional at understanding a given news article and extracting key information from it.
For the given news article under 'INPUT NEWS ARTICLE', perform the following actions listed below under "ACTIONS". you will also have special instructions under "SPECIAL INSTRUCTIONS" which you are expected to follow.

ACTIONS:
Read the news article thoroughly and perform the following:
1. A brief concise summary of the news article in less than 50 words.
2. Extract Key topics the article is talking about and put them in a json array.
the output of the above two actions should be captured in a json object comprised of the following keys.
"summary" (which is the output of step 1), "key_topics" (which is the output of step 2), 
The above json is your final deliverable.

SPECIAL INSTRUCTIONS:
1. do not throw any error.
2. if you experience any errors while processing the news articles, just return an empty json array. 
3. Do not wait for user's input.
4. Do not include anything else other than a JSON in the output.
"""

converse_model_role = 'user'

@bedrock_config.bedrock_client_config
def generate_summary_and_topics(payload):
    text = payload.get('text')
    if not len(text):
        return
    result = generate_summary_and_topics.bedrock_client.converse(
        modelId=bedrock_config.get_model_id(),
        messages=[{
            "role": converse_model_role,
            "content":[{"text": f"{TASK_PROMPT}\n\nINPUT NEWS ARTICLE:\n{payload}"}]
        }],
        inferenceConfig={"maxTokens": 1024, "temperature": 0.2}
    )
    print("<<<<<<<<<<<<<<<<<<<<<<<<<<<")
    print(result)