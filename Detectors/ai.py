
import openai
openai.api_key = "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"

def gpt3(prompt):
    response = openai.Completion.create(
        prompt=prompt,
        engine='davinci',
        max_tokens=25,
        temperature=0.9,
        top_p=1,
        frequency_penalty=0.5,
        presence_penalty=0.5,
        stop=["Student:"])
    answer = response.choices[0]['text']
    return answer