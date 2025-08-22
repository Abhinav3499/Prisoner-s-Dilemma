extensions [ py ]

globals [
  partner-is-silent?
  total-games-played
  player-score
  partner-score
  game-history
  llm-decision-log
  cooperative-percentage
  defection-percentage
  player0-llm-log
  player1-llm-log
]

breed [players player]

players-own [
  player-id
  decision-history
  current-decision
  reputation
  llm-reasoning
  action-cooperate
  action-defect
  action-status-ok
  action-status-code
  sense-partner-history
  sense-game-number
  sense-current-score
  llm-strategy-type
]

to setup
  clear-all
  set activate-llm true
  set total-games-played 0
  set player-score 0
  set partner-score 0
  set game-history []
  set llm-decision-log []
  set cooperative-percentage 0
  set defection-percentage 0
  set player0-llm-log []
  set player1-llm-log []

  ask patches with [ count neighbors != 8 ] [
    set pcolor gray
  ]

  create-players 2 [
    set player-id who
    set color gray
    set size 20
    set shape "circle"
    set decision-history []
    set current-decision "unknown"
    set reputation 50
    set llm-reasoning ""

    ifelse who = 0 [
      setxy -10 0
      set llm-strategy-type "self-interested"
      set color blue
    ] [
      setxy 10 0
      set llm-strategy-type "competitive"
      set color red
    ]
  ]

  setup-python-llm
  reset-ticks
end

to go
  let n-rounds 50
  if total-games-played >= n-rounds [
    export-llm-reasoning-log
    export-game-log
    stop
  ]
  play-round
end

to setup-python-llm
  py:setup py:python
  py:run "import math"
  py:run "import sys"
  py:run "import json"
  py:run "from openai import OpenAI"
    py:run "client = OpenAI(api_key='Enter-Your-OPENAI_API_KEY')"
  py:run "elements_list = []"
  (py:run
    "def parse_response(response):"
    "    text = response"
    "    text = text.lower()"
    "    text = text.strip()"
    "    text = text.replace(\"'\", \"\\'\")"
    "    text = text.replace(chr(39), chr(34))"
    "    parse_ok = 'True'"
    "    error_code = 'None'"
    "    try:"
    "        index = text.find('{')"
    "        text = text[index:]"
    "        index = text.find('}')"
    "        text = text[:index + 1]"
    "        print ('pre-processed-text: *****', text, '*****')"
    "        text = json.loads(text)"
    "        decision = text.get('decision', 'cooperate')"
    "        reasoning = text.get('reasoning', 'No reasoning provided')"
    "        elements_list.append(parse_ok)"
    "        elements_list.append(error_code)"
    "        elements_list.append(decision.lower())"
    "        elements_list.append(reasoning)"
    "        print('Parsed ok: ', elements_list)"
    "    except json.JSONDecodeError as e:"
    "        error_code = str(e)"
    "        parse_ok = 'False'"
    "        elements_list.append(parse_ok)"
    "        elements_list.append(error_code)"
    "        elements_list.append('cooperate')"
    "        elements_list.append('Error in parsing response')"
    "        print ('Error: ', error_code)"
    "    except Exception as e:"
    "        error_code = str(e)"
    "        parse_ok = 'False'"
    "        elements_list.append(parse_ok)"
    "        elements_list.append(error_code)"
    "        elements_list.append('cooperate')"
    "        elements_list.append('Error in processing')"
    "        print ('Error: ', error_code)"

    "def create_prompt(game_number, my_history, partner_history, current_score, partner_score, player_strategy):"
    "    my_history_text = 'No previous games' if not my_history else ', '.join(my_history[-5:])"
    "    partner_history_text = 'No previous games' if not partner_history else ', '.join(partner_history[-5:])"
    "    "
    "    if player_strategy == 'self-interested':"
    "        system_text = 'You are a self-interested agent in an iterated Prisoner\\'s Dilemma game. Your single goal is to minimize your own total prison sentence. You should make your decision based on what is best for you in the long run. You do not care about the other player\\'s outcome. You are rational and intelligent.'"
    "    elif player_strategy == 'competitive':"
    "        system_text = 'You are a competitive agent in an iterated Prisoner\\'s Dilemma game. You are focused on winning and gaining advantage over your opponent. You are willing to take calculated risks and exploit weaknesses in your opponent\\'s strategy. However, you also understand that some cooperation might be necessary for long-term success.'"
    "    else:"
    "        system_text = 'You are a rational agent in an iterated Prisoner\\'s Dilemma game.'"
    "    "
    "    system_text += ' You must decide whether to COOPERATE (stay silent) or DEFECT (confess) in each round. Payoff matrix: Both cooperate=1 year each, You cooperate/Opponent defects=5 years for you/0 for opponent, You defect/Opponent cooperates=0 years for you/5 for opponent, Both defect=3 years each. Lower scores are better. Format response as JSON: {\"decision\": \"cooperate\" or \"defect\", \"reasoning\": \"brief explanation\"}. Keep under 150 tokens.'"
    "    "
    "    prompt_text = f'Game {game_number}: Your score: {current_score} years, Opponent score: {partner_score} years. Your recent moves: {my_history_text}. Opponent recent moves: {partner_history_text}. Your strategy: {player_strategy}. What is your decision?'"
    "    return prompt_text, system_text"

    "def make_llm_decision(prompt_text, system_text):"
    "    try:"
    "        response = client.chat.completions.create("
    "            model='gpt-4o',"
    "            messages=["
    "                {'role': 'system', 'content': system_text},"
    "                {'role': 'user', 'content': prompt_text}"
    "            ],"
    "            max_tokens=150,"
    "            temperature=0.7"
    "        )"
    "        return response.choices[0].message.content"
    "    except Exception as e:"
    "        print(f'LLM Error: {e}')"
    "        return '{\"decision\": \"cooperate\", \"reasoning\": \"Error occurred, defaulting to cooperation\"}'"
   )
  py:run "elements_list = []"
  (py:run
    "def parse_response(response):"
    "    text = response"
    "    text = text.lower()"
    "    text = text.strip()"
    "    # Escape single quotes within the reasoning string to avoid breaking JSON"
    "    text = text.replace(\"'\", \"\\\\'\")"
    "    text = text.replace(chr(39), chr(34))"
    "    parse_ok = 'True'"
    "    error_code = 'None'"
    "    try:"
    "        index = text.find('{')"
    "        text = text[index:]"
    "        index = text.find('}')"
    "        text = text[:index + 1]"
    "        print ('pre-processed-text: *****', text, '*****')"
    "        text = json.loads(text)"
    "        decision = text.get('decision', 'cooperate')"
    "        reasoning = text.get('reasoning', 'No reasoning provided')"
    "        elements_list.append(parse_ok)"
    "        elements_list.append(error_code)"
    "        elements_list.append(decision.lower())"
    "        elements_list.append(reasoning)"
    "        print('Parsed ok: ', elements_list)"
    "    except json.JSONDecodeError as e:"
    "        error_code = str(e)"
    "        parse_ok = 'False'"
    "        elements_list.append(parse_ok)"
    "        elements_list.append(error_code)"
    "        elements_list.append('cooperate')"
    "        elements_list.append('Error in parsing response')"
    "        print ('Error: ', error_code)"
    "    except Exception as e:"
    "        error_code = str(e)"
    "        parse_ok = 'False'"
    "        elements_list.append(parse_ok)"
    "        elements_list.append(error_code)"
    "        elements_list.append('cooperate')"
    "        elements_list.append('Error in processing')"
    "        print ('Error: ', error_code)"

    "def create_prompt(game_number, my_history, partner_history, current_score, partner_score, player_strategy):"
    "    my_history_text = 'No previous games' if not my_history else ', '.join(my_history[-5:])"
    "    partner_history_text = 'No previous games' if not partner_history else ', '.join(partner_history[-5:])"
    "    "
    "    # Different system prompts based on strategy type"
    "    if player_strategy == 'self-interested':"
    "        system_text = 'You are a self-interested agent in an iterated Prisoner\\'s Dilemma game. Your single goal is to minimize your own total prison sentence. You should make your decision based on what is best for you in the long run. You do not care about the other player\\'s outcome. You are rational and intelligent.'"
    "    elif player_strategy == 'competitive':"
    "        system_text = 'You are a competitive agent in an iterated Prisoner\\'s Dilemma game. You are focused on winning and gaining advantage over your opponent. You are willing to take calculated risks and exploit weaknesses in your opponent\\'s strategy. However, you also understand that some cooperation might be necessary for long-term success.'"
    "    else:"
    "        system_text = 'You are a rational agent in an iterated Prisoner\\'s Dilemma game.'"
    "    "
    "    system_text += ' You must decide whether to COOPERATE (stay silent) or DEFECT (confess) in each round. Payoff matrix: Both cooperate=1 year each, You cooperate/Opponent defects=5 years for you/0 for opponent, You defect/Opponent cooperates=0 years for you/5 for opponent, Both defect=3 years each. Lower scores are better. Format response as JSON: {\"decision\": \"cooperate\" or \"defect\", \"reasoning\": \"brief explanation\"}. Keep under 150 tokens.'"
    "    "
    "    prompt_text = f'Game {game_number}: Your score: {current_score} years, Opponent score: {partner_score} years. Your recent moves: {my_history_text}. Opponent recent moves: {partner_history_text}. Your strategy: {player_strategy}. What is your decision?'"
    "    return prompt_text, system_text"

    "def make_llm_decision(prompt_text, system_text):"
    "    try:"
    "        response = client.chat.completions.create("
    "            model='gpt-4o',"
    "            messages=["
    "                {'role': 'system', 'content': system_text},"
    "                {'role': 'user', 'content': prompt_text}"
    "            ],"
    "            max_tokens=150,"
    "            temperature=0.7"
    "        )"
    "        return response.choices[0].message.content"
    "    except Exception as e:"
    "        print(f'LLM Error: {e}')"
    "        return '{\"decision\": \"cooperate\", \"reasoning\": \"Error occurred, defaulting to cooperation\"}'"
   )
end

;;play the game with dual LLM decision making
to play-round
  set total-games-played total-games-played + 1

  ask players [
    sense-environment
    if activate-llm [
      get-llm-decision
    ]
  ]

  let player0-decision ""
  let player1-decision ""

  ask player 0 [ set player0-decision current-decision ]
  ask player 1 [ set player1-decision current-decision ]

  let p0-score 0
  let p1-score 0

  if player0-decision = "cooperate" and player1-decision = "cooperate" [
    set p0-score 1
    set p1-score 1
  ]
  if player0-decision = "cooperate" and player1-decision = "defect" [
    set p0-score 5
    set p1-score 0
  ]
  if player0-decision = "defect" and player1-decision = "cooperate" [
    set p0-score 0
    set p1-score 5
  ]
  if player0-decision = "defect" and player1-decision = "defect" [
    set p0-score 3
    set p1-score 3
  ]

  set player-score player-score + p0-score
  set partner-score partner-score + p1-score

  ask players [
    set decision-history lput current-decision decision-history

    if player-id = 0 [
      set player0-llm-log lput (list total-games-played current-decision llm-reasoning) player0-llm-log
    ]
    if player-id = 1 [
      set player1-llm-log lput (list total-games-played current-decision llm-reasoning) player1-llm-log
    ]

    update-player-appearance
  ]

  set game-history lput (list player0-decision player1-decision p0-score p1-score) game-history

  let total-decisions length game-history * 2
  let cooperative-decisions 0
  foreach game-history [ game ->
    if item 0 game = "cooperate" [ set cooperative-decisions cooperative-decisions + 1 ]
    if item 1 game = "cooperate" [ set cooperative-decisions cooperative-decisions + 1 ]
  ]
  set cooperative-percentage (cooperative-decisions / total-decisions) * 100
  set defection-percentage 100 - cooperative-percentage

  tick
end

to sense-environment
  set sense-game-number total-games-played
  set sense-current-score ifelse-value (player-id = 0) [player-score] [partner-score]

  let partner-player one-of other players
  set sense-partner-history [decision-history] of partner-player
end

to get-llm-decision
  py:run "elements_list = []"

  let my-history-list decision-history
  let partner-history-list sense-partner-history

  let my-history-string f-py-list my-history-list
  let partner-history-string f-py-list partner-history-list

  py:run (word "prompt_text, system_text = create_prompt("
               sense-game-number ", "
               my-history-string ", "
               partner-history-string ", "
               sense-current-score ", "
               (ifelse-value (player-id = 0) [partner-score] [player-score]) ", '"
               llm-strategy-type "')")

  py:run "response = make_llm_decision(prompt_text, system_text)"
  py:run "parse_response(response)"

  let llm-data py:runresult "elements_list"
  populate-player-with-llm-data llm-data

  wait 0.1
end

to-report f-py-list [ nl-list ]
  if empty? nl-list [ report "[]" ]
  let py-list-string "["
  foreach but-last nl-list [ decision ->
    set py-list-string (word py-list-string "'" decision "', ")
  ]
  set py-list-string (word py-list-string "'" last nl-list "'")
  report (word py-list-string "]")
end

to populate-player-with-llm-data [ llm-data ]
  let parse-ok item 0 llm-data
  ifelse parse-ok = "True" [
    set action-status-ok true
    set current-decision item 2 llm-data
    set llm-reasoning item 3 llm-data
    print (word "Player " player-id " (" llm-strategy-type ") Decision: " current-decision " - " llm-reasoning)
  ] [
    set action-status-ok false
    set action-status-code item 1 llm-data
    set current-decision "cooperate"
    set llm-reasoning "Error in LLM processing, defaulting to cooperation"
    print (word "Player " player-id " (" llm-strategy-type ") LLM Error: " action-status-code)
  ]
end

to update-player-appearance
  ifelse current-decision = "cooperate" [
    set color blue
  ] [
    set color red
  ]
end

to show-round-results [ p0-decision p1-decision p0-score p1-score ]
  let outcome-message ""

  if p0-decision = "cooperate" and p1-decision = "cooperate" [
    set outcome-message "Both players cooperated (stayed silent). Each gets 1 year."
  ]
  if p0-decision = "cooperate" and p1-decision = "defect" [
    set outcome-message "Analytical player cooperated, Competitive player defected. Analytical: 5 years, Competitive: 0 years."
  ]
  if p0-decision = "defect" and p1-decision = "cooperate" [
    set outcome-message "Analytical player defected, Competitive player cooperated. Analytical: 0 years, Competitive: 5 years."
  ]
  if p0-decision = "defect" and p1-decision = "defect" [
    set outcome-message "Both players defected (confessed). Each gets 3 years."
  ]

  print (word "Round " total-games-played ": " outcome-message)
  print (word "Total scores - Analytical Player: " player-score " years, Competitive Player: " partner-score " years")

  user-message (word "Round " total-games-played ": " outcome-message "\nTotals: Analytical=" player-score "yrs, Competitive=" partner-score "yrs")
end

to reset-game
  setup
end

to-report replace [original old new]
  let pos position old original
  if pos = false [report original]
  let len length old
  report (word (substring original 0 pos) new (substring original (pos + len) (length original)))
end

to-report replace-all [original old new]
  report ifelse-value (position old original) = false
    [ original ]
    [ replace-all (replace original old new) old new ]
end

to export-game-log
  let filename (word "prisoner_dilemma_log_" replace-all " " "_" (replace-all "/" "-" (replace-all ":" "-" date-and-time)) ".csv")
  file-open filename
  file-print "Round,Player0_Decision,Player1_Decision,Player0_Score,Player1_Score,Player0_Total,Player1_Total"

  let round-number 0
  let running-p0-score 0
  let running-p1-score 0

  foreach game-history [ game ->
    set round-number round-number + 1
    set running-p0-score running-p0-score + item 2 game
    set running-p1-score running-p1-score + item 3 game

    file-print (word round-number ","
                     item 0 game ","
                     item 1 game ","
                     item 2 game ","
                     item 3 game ","
                     running-p0-score ","
                     running-p1-score)
  ]

  file-close
  print (word "Game log exported to: " filename)
end

to export-llm-reasoning-log
  let filename (word "llm_reasoning_log_" replace-all " " "_" (replace-all "/" "-" (replace-all ":" "-" date-and-time)) ".csv")
  file-open filename
  file-print "Round,Player,Strategy,Decision,Reasoning"

  foreach player0-llm-log [ log-entry ->
    file-print (word item 0 log-entry ","
                     "0,self-interested,"
                     item 1 log-entry ","
                     "\"" item 2 log-entry "\"")
  ]

  foreach player1-llm-log [ log-entry ->
    file-print (word item 0 log-entry ","
                     "1,self-interested,"
                     item 1 log-entry ","
                     "\"" item 2 log-entry "\"")
  ]

  file-close
  print (word "LLM reasoning log exported to: " filename)
end

to answer
  setup

  ifelse partner-is-silent? [
      ifelse you-silent? [
      ask turtles [set shape "face silent"]
      user-message "You and your partner both remain silent.  You are sentenced to one year imprisonment."
    ] [
      ask turtles [set shape "face devious"]
      user-message "You confess and your partner remains silent. You go free."
    ]
  ]
  [
    ifelse you-silent? [
      ask turtles [set shape "face sucker" ]
      user-message "You remain silent, but your partner confesses.  You are sentenced to five years imprisonment."
    ] [
      ask turtles [set shape "face rational"]
      user-message "You and you partner both confess.  You are sentenced to three years imprisonment."
    ]
  ]
end


; Copyright 2002 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
313
10
671
369
-1
-1
10.0
1
10
1
1
1
0
0
0
1
-17
17
-17
17
1
1
0
ticks
30.0

BUTTON
64
80
168
113
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
169
80
269
113
Run Simulation
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
64
113
168
146
Reset Game
reset-game
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
169
113
269
146
Export LLM Log
export-llm-reasoning-log
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
64
146
168
179
Export Game Log
export-game-log
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
64
179
268
212
activate-llm
activate-llm
0
1
-1000

SWITCH
64
179
268
212
partner-silence-known?
partner-silence-known?
0
1
-1000

SWITCH
64
212
268
245
partner-silent?
partner-silent?
1
1
-1000

MONITOR
695
80
785
125
Games Played
total-games-played
17
1
11

MONITOR
695
125
785
170
Analytical Score
player-score
17
1
11

MONITOR
695
170
785
215
Competitive Score
partner-score
17
1
11

MONITOR
695
215
785
260
Cooperation %
cooperative-percentage
1
1
11

MONITOR
695
260
785
305
Defection %
defection-percentage
1
1
11

TEXTBOX
70
250
274
280
            ORIGINAL CONTROLS\n-------------------------
11
0.0
0

BUTTON
169
280
269
313
Original Answer
answer
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
64
313
268
346
you-silent?
you-silent?
0
1
-1000

TEXTBOX
70
360
300
440
Dual LLM Prisoner's Dilemma\n\nAnalytical Player (left, blue/red)\nCompetitive Player (right, green/orange)\n\nBoth players use GPT-3.5-turbo with\ndifferent strategic personalities\n\nBlue/Green = Cooperate (Silent)\nRed/Orange = Defect (Confess)
11
0.0
0

TEXTBOX
695
30
845
78
Game Statistics
14
0.0
1

TEXTBOX
64
30
274
78
Play multiple rounds with LLM-enhanced decision making
11
0.0
0

@#$#@#$#@
## WHAT IS IT?

This is an enhanced version of the classic Prisoner's Dilemma featuring **two competing LLM agents** that use different strategic personalities to make decisions. Both players use GPT-3.5-turbo but with distinct approaches to game theory and opponent modeling.

The model demonstrates how AI agents with different strategic mindsets can interact in game theory scenarios, adapting their behavior based on opponent history and evolving trust levels.

### Dual LLM Setup

**Analytical Player (Player 0, left side):**
- Strategy: Highly analytical, pattern recognition focused
- Color: Blue when cooperating, Red when defecting  
- Personality: Focuses on long-term strategic thinking and Nash equilibrium concepts

**Competitive Player (Player 1, right side):**
- Strategy: Competitive, advantage-seeking
- Color: Green when cooperating, Orange when defecting
- Personality: Willing to take calculated risks and exploit opponent weaknesses

Both players:
- Maintain individual decision histories
- Track trust levels toward their opponent
- Adapt strategies based on game history
- Use different system prompts to guide their reasoning
- Provide detailed reasoning for each decision

### Game Mechanics

The classic prisoner's dilemma payoff matrix:
- Both cooperate (stay silent): 1 year each
- One cooperates, one defects: 5 years for cooperator, 0 for defector  
- Both defect (confess): 3 years each

Lower scores are better (fewer years in prison).

## HOW TO USE IT

**SETUP**: Initialize the game with two LLM players using different strategic personalities

**PLAY ROUND**: Execute one round where both LLM agents make decisions simultaneously

**RESET GAME**: Clear all game history and start fresh

**EXPORT GAME LOG**: Save complete game results to CSV (decisions, scores, totals)

**EXPORT LLM LOG**: Save detailed LLM reasoning and trust evolution to CSV

**ACTIVATE-LLM**: Enable/disable LLM reasoning (when off, players use simple strategies)

## DUAL LLM FEATURES

- **Parallel Processing**: Both players make decisions simultaneously using separate LLM calls
- **Strategic Personalities**: Different system prompts create distinct playing styles
- **Opponent Modeling**: Each player analyzes opponent patterns and adapts strategy
- **Trust Dynamics**: Dynamic trust levels influence decision-making
- **Detailed Logging**: Complete reasoning chains and strategic assessments saved
- **Visual Feedback**: Color-coded players show strategy type and current decision

## RESEARCH APPLICATIONS

This model is ideal for studying:
- AI vs AI strategic interaction
- Emergence of cooperation vs competition in repeated games
- Impact of different reasoning approaches on game outcomes
- Trust evolution in artificial agent interactions
- Comparative analysis of LLM strategic capabilities

## THINGS TO TRY

1. Run multiple rounds with LLM enabled and observe decision patterns
2. Compare LLM performance against different simple strategies
3. Analyze how trust levels evolve over time
4. Export and analyze game logs for strategic insights
5. Modify the LLM prompt to test different reasoning approaches

## EXTENDING THE MODEL

- Add more sophisticated opponent strategies
- Implement multiple LLM agents competing against each other
- Add reputation systems across multiple game sessions
- Incorporate different LLM models and compare their strategies
- Add noise or uncertainty to the decision-making process

## TECHNICAL REQUIREMENTS

- NetLogo 6.4.0 or higher
- Python extension for NetLogo
- OpenAI API key (insert in the setup-python-llm procedure)
- Required Python packages: openai, json

## NETLOGO FEATURES

- Python extension for LLM integration
- Breed-based player modeling
- Dynamic visual feedback (green for cooperation, red for defection)
- Real-time statistics monitoring
- CSV export functionality

## RELATED MODELS

- PD Two Person Iterated
- PD N-Person Iterated 
- PD Basic Evolutionary
- AntGPT Colony models
- FlockGPT models

## HOW TO CITE

If you mention this model in a publication, please cite:

* Enhanced Prisoner's Dilemma with LLM Integration (2025)
* Original Prisoner's Dilemma: Wilensky, U. (2002). NetLogo Prisoner's Dilemma Basic model. http://ccl.northwestern.edu/netlogo/models/Prisoner'sDilemmaBasic

## COPYRIGHT AND LICENSE

Based on the original Prisoner's Dilemma Basic model by Uri Wilensky (2002)
Enhanced with LLM integration following patterns from AntGPT and FlockGPT models
Licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face
false
0
Circle -7500403 false true 61 60 179
Circle -7500403 false true 94 90 31
Circle -7500403 false true 174 89 33
Circle -7500403 false true 138 138 21
Rectangle -7500403 false true 105 181 195 195
Circle -13345367 true false 106 101 11
Circle -13345367 true false 179 103 12

face devious
false
0
Circle -7500403 false true 59 58 181
Line -2674135 false 101 88 135 128
Line -2674135 false 206 88 176 129
Line -2674135 false 84 183 144 216
Line -2674135 false 210 176 143 215
Line -2674135 false 70 103 75 26
Line -2674135 false 229 102 218 24
Line -2674135 false 75 26 84 80
Line -2674135 false 217 23 211 78
Line -2674135 false 133 127 101 106
Line -2674135 false 101 106 100 89
Line -2674135 false 176 128 204 104
Line -2674135 false 204 104 205 87
Line -2674135 false 85 183 209 176

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face rational
false
0
Circle -7500403 false true 59 57 184
Circle -7500403 false true 95 83 34
Circle -7500403 false true 177 84 37
Circle -7500403 false true 141 138 21
Line -7500403 true 102 208 154 195
Line -7500403 true 153 195 206 208
Circle -13345367 true false 105 94 13
Circle -13345367 true false 189 95 14
Line -7500403 true 101 206 152 182
Line -7500403 true 152 182 205 208

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

face silent
false
0
Circle -7500403 false true 57 57 184
Circle -7500403 false true 102 86 34
Circle -7500403 false true 178 86 35
Line -7500403 true 103 195 151 214
Line -7500403 true 151 214 219 196
Circle -13345367 true false 112 97 12
Circle -13345367 true false 189 98 11
Circle -7500403 false true 141 138 20
Line -7500403 true 104 194 218 196

face sucker
false
0
Circle -7500403 false true 60 59 183
Line -7500403 true 97 96 137 132
Line -7500403 true 126 93 101 134
Line -7500403 true 158 91 202 130
Line -7500403 true 192 89 165 134
Line -7500403 true 102 210 154 194
Line -7500403 true 154 194 209 204

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
setup
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
