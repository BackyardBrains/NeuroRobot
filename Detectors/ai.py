import openai
openai.api_key = "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"
response = openai.Completion.create(engine="davinci", prompt="This is a test", max_tokens=5)
answer = response.choices[0]['text']