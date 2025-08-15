# Prisoner's Dilemma LLM Simulation

This project simulates the Iterated Prisoner's Dilemma using NetLogo models and analyzes the results with Python. It explores how different agent strategies (self-interested, competitive, cooperative/else) interact, including agents powered by large language models (LLMs).

## Contents

- **NetLogo Models**: Two main models:
  - `Prisoner's Dilemma Basic.nlogo`: Classic agent-based simulation.
  - `Prisoner's Dilemma LLM.nlogo`: Integrates LLMs (e.g., OpenAI GPT) to make agent decisions based on game context and history.
- **CSV Logs**: Game outcomes and LLM reasoning for various strategy pairings (e.g., self-interested vs. competitive).
- **Results.ipynb**: Python notebook for loading, analyzing, and visualizing simulation results, including cooperation/defection rates and average scores by strategy.

## How It Works

- Agents play repeated rounds, choosing to cooperate or defect based on their strategy and, for LLM agents, contextual reasoning.
- Results are logged for each pairing and analyzed to compare strategies and LLM behavior.

## Usage

1. Run the NetLogo models to generate CSV logs.
2. Open `Results.ipynb` to analyze and visualize the outcomes.

## Requirements

- NetLogo with Python extension
- OpenAI API key (for LLM model)
- Python (pandas, matplotlib, numpy)

## License

MIT License
