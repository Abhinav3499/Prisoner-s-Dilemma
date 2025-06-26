import pynetlogo
from llm import query_gemini
import time

def query_llm_1(history):
    return query_gemini(history, player_id=1)

def query_llm_2(history):
    return query_gemini(history, player_id=2)

NUM_ROUNDS = 10

def main():
    netlogo = pynetlogo.NetLogoLink(gui=False)
    netlogo.load_model("Prisoner's Dilemma Basic.nlogo")
    netlogo.command('setup')
    history = []
    for round in range(NUM_ROUNDS):
        move1 = query_llm_1(history)
        move2 = query_llm_2(history)
        netlogo.command(f'set you-silent? {"true" if move1 == "silent" else "false"}')
        netlogo.command(f'set partner-silent? {"true" if move2 == "silent" else "false"}')
        netlogo.command('answer')
        result = netlogo.report('result-message')
        history.append((move1, move2, result))
        print(f"Round {round+1}: Player1: {move1}, Player2: {move2}, Result: {result}")
        time.sleep(10)
    netlogo.kill_workspace()

if __name__ == "__main__":
    main()