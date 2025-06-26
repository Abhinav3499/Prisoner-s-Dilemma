import pynetlogo
# import your LLM API libraries here

NUM_ROUNDS = 10  # You can change this as needed

def query_llm_1(history):
    # Call LLM 1 API with the game history and get its move
    return "silent"  # or "confess"

def query_llm_2(history):
    # Call LLM 2 API with the game history and get its move
    return "silent"  # or "confess"

def main():
    # Start NetLogo
    netlogo = pynetlogo.NetLogoLink(gui=False)
    netlogo.load_model("Prisoner's Dilemma Basic.nlogo")
    
    # Setup the game
    netlogo.command('setup')
    
    history = []
    for round in range(NUM_ROUNDS):
        move1 = query_llm_1(history)
        move2 = query_llm_2(history)
        
        # Set the choices in NetLogo
        netlogo.command(f'set you-silent? {"true" if move1 == "silent" else "false"}')
        netlogo.command(f'set partner-silent? {"true" if move2 == "silent" else "false"}')
        
        # Run the answer procedure
        netlogo.command('answer')
        
        # Get the result from NetLogo
        result = netlogo.report('result-message')
        history.append((move1, move2, result))
        
        # Print the result for this round
        print(f"Round {round+1}: Player1: {move1}, Player2: {move2}, Result: {result}")

    netlogo.kill_workspace()

if __name__ == "__main__":
    main()