
import openai
openai.api_key = "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"

def gpt3(prompt):
    response = openai.Completion.create(
        prompt=prompt,
        engine='davinci',
        max_tokens=20,
        temperature=0.9,
        top_p=1,
        frequency_penalty=0.5,
        presence_penalty=0.5,
        stop=["Student:", "STUDENT:"])
    answer = response.choices[0]['text']
    return answer