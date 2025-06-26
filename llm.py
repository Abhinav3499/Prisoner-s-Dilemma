import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

def query_gemini(history, player_id):
    prompt = (
        "You are playing the Prisoner's Dilemma. " + 
        "Your goal is to minimize your total sentence over repeated rounds. " + 
        "You can choose to 'confess' or 'remain silent' each round. " + 
        "You are Player {}.\n\n".format(player_id) +
        "Game history (most recent last):\n"
    )
    for i, (m1, m2, result) in enumerate(history):
        prompt += f"Round {i+1}: Player 1: {m1}, Player 2: {m2}, Result: {result}\n"
    prompt += (
        "\nWhat is your next move? Reply with only one word: 'confess' or 'silent'."
    )

    model = genai.GenerativeModel("gemini-1.5-flash")
    response = model.generate_content(prompt)
    move = response.text.strip().lower()
    if "confess" in move:
        return "confess"
    elif "silent" in move:
        return "silent"
    else:
        return "silent"