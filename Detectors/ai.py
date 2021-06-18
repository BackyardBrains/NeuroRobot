
import openai
openai.api_key = "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"

def gpt3(prompt):
    response = openai.Completion.create(
        prompt=prompt,
        engine='davinci',
        max_tokens=25,
        temperature=0.5,
        top_p=1,
        frequency_penalty=0.5,
        presence_penalty=0.5,
        stop=["Student:"])
    answer = response.choices[0]['text']
    return answer