
import openai
openai.api_key = "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"

def gpt3(prompt):
    response = openai.Completion.create(
        prompt=prompt,
        engine='davinci',
        max_tokens=10,
        temperature=0.9,
        top_p=1,
        frequency_penalty=0.5,
        presence_penalty=0.5,
        stop=["Student:", "STUDENT:"])
    answer = response.choices[0]['text']
    return answer