import os
import openai
openai.api_key = "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"

openai.Completion.create(engine="davinci", prompt="This is a test", max_tokens=5)

def gpt3(prompt="This is a test", engine='davinci', max_tokens=5):
    response = openai.Completion.create(prompt=prompt, engine=engine)
    answer = response.choices[0]['text']
    return answer