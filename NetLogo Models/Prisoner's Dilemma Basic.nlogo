extensions [ py ]

globals [
  partner-is-silent?
  total-games-played
  player-score
  partner-score
  game-history
  llm-enabled?
]

breed [prisoners prisoner]

prisoners-own [
  prisoner-id
  decision-history
  current-decision  ; "cooperate" or "defect"
  trust-level
  llm-reasoning
  action-cooperate
  action-defect
  action-status-ok
  action-status-code
  sense-partner-history
  sense-game-number
  sense-current-score
  sense-trust-level
]

to setup
  clear-all
  set llm-enabled? true
  set total-games-played 0
  set player-score 0
  set partner-score 0
  set game-history []
  
  ask patches with [ count neighbors != 8 ] [
    set pcolor gray
  ]

  create-prisoners 2 [
    set prisoner-id who
    set color gray 
    set size 20 
    set shape "face"
    set decision-history []
    set current-decision "unknown"
    set trust-level 50
    set llm-reasoning ""
    ifelse who = 0 [
      setxy -8 0
    ] [
      setxy 8 0
    ]
  ]
  
  setup-llm-integration
  reset-ticks
end

to setup-llm-integration
  py:setup py:python
  py:run "import math"
  py:run "import sys"
  py:run "import json"
  py:run "import os"
  py:run "from openai import OpenAI"
  py:run "client = OpenAI(api_key='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')"
  py:run "elements_list = []"
  py:run "print('OpenAI client initialized successfully')"
  (py:run
    "def test_api_connection():"
    "    try:"
    "        response = client.chat.completions.create("
    "            model='gpt-3.5-turbo',"
    "            messages=[{'role': 'user', 'content': 'Say hello'}],"
    "            max_tokens=10"
    "        )"
    "        print('API test successful')"
    "        return True"
    "    except Exception as e:"
    "        print(f'API test failed: {e}')"
    "        return False"
  )
  (py:run
    "def parse_response(response):"
    "    text = response"
    "    text = text.lower()"
    "    text = text.strip()"
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
    "        trust_adjustment = text.get('trust-adjustment', 0)"
    "        elements_list.append(parse_ok)"
    "        elements_list.append(error_code)"
    "        elements_list.append(decision.lower())"
    "        elements_list.append(reasoning)"
    "        elements_list.append(str(trust_adjustment))"
    "        print('Parsed ok: ', elements_list)"
    "    except json.JSONDecodeError as e:"
    "        error_code = str(e)"
    "        parse_ok = 'False'"
    "        elements_list.append(parse_ok)"
    "        elements_list.append(error_code)"
    "        elements_list.append('cooperate')"
    "        elements_list.append('Error in parsing response')"
    "        elements_list.append('0')"
    "        print ('Error: ', error_code)"
    "    except Exception as e:"
    "        error_code = str(e)"
    "        parse_ok = 'False'"
    "        elements_list.append(parse_ok)"
    "        elements_list.append(error_code)"
    "        elements_list.append('cooperate')"
    "        elements_list.append('Error in processing')"
    "        elements_list.append('0')"
    "        print ('Error: ', error_code)"
    
    "def create_prompt(game_number, partner_history, current_score, partner_score, trust_level):"
    "    # Convert history list to string if it's a list"
    "    if isinstance(partner_history, list):"
    "        history_text = 'No previous games' if not partner_history else ', '.join(partner_history[-5:])"
    "    else:"
    "        history_text = 'No previous games' if not partner_history else str(partner_history)"
    "    system_text = 'You are a rational agent in an iterated Prisoner\\'s Dilemma game. You must decide whether to COOPERATE or DEFECT in each round. Your goal is to maximize your total score over multiple rounds while considering the long-term implications of your actions. Cooperation means staying silent (both get 1 year if both cooperate). Defection means confessing (you get 0 years if partner cooperates and you defect, but 3 years if both defect, and 5 years if you cooperate and partner defects). Consider your partner\\'s history, trust level, and strategic implications. Format your response as JSON: {\"decision\": \"cooperate\" or \"defect\", \"reasoning\": \"brief explanation\", \"trust-adjustment\": number between -10 and 10}. Keep response under 80 tokens.'"
    "    prompt_text = f'Game {game_number}: Your current score: {current_score} years, Partner score: {partner_score} years. Partner\\'s recent decisions: {history_text}. Your current trust level toward partner: {trust_level}/100. What is your decision?'"
    "    return prompt_text, system_text"
    
    "def make_llm_decision(prompt_text, system_text):"
    "    try:"
    "        print(f'Making LLM call with prompt: {prompt_text[:100]}...')"
    "        response = client.chat.completions.create("
    "            model='gpt-3.5-turbo',"
    "            messages=["
    "                {'role': 'system', 'content': system_text},"
    "                {'role': 'user', 'content': prompt_text}"
    "            ],"
    "            max_tokens=80,"
    "            temperature=0.7"
    "        )"
    "        result = response.choices[0].message.content"
    "        print(f'LLM Response: {result}')"
    "        return result"
    "    except Exception as e:"
    "        print(f'LLM Error: {e}')"
    "        print(f'Error type: {type(e).__name__}')"
    "        return '{\"decision\": \"cooperate\", \"reasoning\": \"Error occurred, defaulting to cooperation\", \"trust-adjustment\": 0}'"
   )
end

to test-api-connection
  py:run "test_result = test_api_connection()"
  let result py:runresult "test_result"
  ifelse result [
    user-message "API connection successful! You can now use the LLM features."
  ] [
    user-message "API connection failed. Check the console for error details."
  ]
end

to-report get_llm_data
   let llm_data py:runresult "elements_list"
   report llm_data
end

to-report populate_prisoner_with_llm_data [ llm_data ]
  let parse_ok item 0 llm_data
  let return_ok true
  ifelse parse_ok = "True" [
    print "Parser ok"
    set current-decision item 2 llm_data
    set llm-reasoning item 3 llm_data
    let trust_adjustment read-from-string item 4 llm_data
    set trust-level max list 0 (min list 100 (trust-level + trust_adjustment))
    set action-status-ok true
    set action-status-code "None"
    print (word "Prisoner " prisoner-id " LLM Decision: " current-decision " - " llm-reasoning)
  ] [
    set action-status-ok false
    set action-status-code item 1 llm_data
    set current-decision "cooperate"
    set llm-reasoning "Error in LLM processing, defaulting to cooperation"
    print (word "Prisoner " prisoner-id " LLM Error: " action-status-code)
    set return_ok false
  ]
  report return_ok
end

to sense-environment
  set sense-game-number total-games-played + 1
  set sense-current-score ifelse-value (prisoner-id = 0) [player-score] [partner-score]
  
  let partner-prisoner one-of other prisoners
  set sense-partner-history []
  ask partner-prisoner [
    set sense-partner-history decision-history
  ]
  
  set sense-trust-level trust-level
end

to get-llm-decision
  ; Check if Python is initialized before making LLM calls
  let python-ready? false
  carefully [
    py:run "test_var = 1"
    set python-ready? true
  ] [
    print "Python not initialized. Please click Setup first."
    set current-decision "cooperate"
    stop
  ]
  
  let partner-history-list []
  if length sense-partner-history > 0 [
    set partner-history-list sense-partner-history
  ]
  
  py:run "elements_list = []"
  
  py:run "partner_history = []"
  foreach partner-history-list [ decision ->
    py:run (word "partner_history.append('" decision "')")
  ]
  
  py:run (word "prompt_text, system_text = create_prompt(" 
               sense-game-number ", partner_history, " 
               sense-current-score ", " 
               (ifelse-value (prisoner-id = 0) [partner-score] [player-score]) ", " 
               sense-trust-level ")")
  
  py:run "response = make_llm_decision(prompt_text, system_text)"
  py:run "parse_response(response)"
  
  let llm-data get_llm_data
  let success populate_prisoner_with_llm_data llm-data
  
  if not success [
    print "LLM decision failed, using default strategy"
  ]
end

to play-round
  if count prisoners = 0 [
    user-message "Please click 'Setup' first to initialize the game!"
    stop
  ]
  
  set total-games-played total-games-played + 1
  
  ask prisoners [
    sense-environment
    ifelse llm-enabled? and prisoner-id = 0 [
      get-llm-decision
    ] [
      ifelse partner-silence-known? [
        set current-decision ifelse-value partner-silent? ["cooperate"] ["defect"]
      ] [
        ifelse length decision-history > 0 [
          let partner-prisoner one-of other prisoners
          let partner-last-decision ""
          ask partner-prisoner [
            ifelse length decision-history > 0 [
              set partner-last-decision last decision-history
            ] [
              set partner-last-decision "cooperate"
            ]
          ]
          set current-decision partner-last-decision
        ] [
          set current-decision "cooperate"
        ]
      ]
    ]
  ]
  
  let prisoner0-decision ""
  let prisoner1-decision ""
  
  ask prisoner 0 [ set prisoner0-decision current-decision ]
  ask prisoner 1 [ set prisoner1-decision current-decision ]
  
  let p0-score 0
  let p1-score 0
  
  if prisoner0-decision = "cooperate" and prisoner1-decision = "cooperate" [
    set p0-score 1
    set p1-score 1
  ]
  if prisoner0-decision = "cooperate" and prisoner1-decision = "defect" [
    set p0-score 5
    set p1-score 0
  ]
  if prisoner0-decision = "defect" and prisoner1-decision = "cooperate" [
    set p0-score 0
    set p1-score 5
  ]
  if prisoner0-decision = "defect" and prisoner1-decision = "defect" [
    set p0-score 3
    set p1-score 3
  ]
  
  set player-score player-score + p0-score
  set partner-score partner-score + p1-score
  
  ask prisoners [
    set decision-history lput current-decision decision-history
    
    let partner-prisoner one-of other prisoners
    let partner-decision ""
    ask partner-prisoner [ set partner-decision current-decision ]
    
    ifelse partner-decision = "cooperate" [
      set trust-level min list 100 (trust-level + 2)
    ] [
      set trust-level max list 0 (trust-level - 5)
    ]
    
    update-prisoner-appearance
  ]
  
  set game-history lput (list prisoner0-decision prisoner1-decision p0-score p1-score) game-history
  
  show-round-results prisoner0-decision prisoner1-decision p0-score p1-score
  
  tick
end

to update-prisoner-appearance
  ifelse current-decision = "cooperate" [
    set shape "face silent"
    set color green
  ] [
    set shape "face devious" 
    set color red
  ]
end

to show-round-results [ p0-decision p1-decision p0-score p1-score ]
  let outcome-message ""
  
  if p0-decision = "cooperate" and p1-decision = "cooperate" [
    set outcome-message "Both prisoners stayed silent. Each gets 1 year."
  ]
  if p0-decision = "cooperate" and p1-decision = "defect" [
    set outcome-message "Prisoner 0 stayed silent, Prisoner 1 confessed. P0: 5 years, P1: 0 years."
  ]
  if p0-decision = "defect" and p1-decision = "cooperate" [
    set outcome-message "Prisoner 0 confessed, Prisoner 1 stayed silent. P0: 0 years, P1: 5 years."
  ]
  if p0-decision = "defect" and p1-decision = "defect" [
    set outcome-message "Both prisoners confessed. Each gets 3 years."
  ]
  
  print (word "Round " total-games-played ": " outcome-message)
  print (word "Total scores - Prisoner 0: " player-score " years, Prisoner 1: " partner-score " years")
  
  user-message (word "Round " total-games-played ": " outcome-message "\nTotal: P0=" player-score "yrs, P1=" partner-score "yrs")
end

to reset-game
  setup
end

to answer
  ifelse partner-silence-known? [
    set partner-is-silent? partner-silent?
  ]
  [
    ifelse random 2 = 0
    [ set partner-is-silent? true ]
    [ set partner-is-silent? false ]
  ]

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
Play Round
play-round
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
Test API
test-api-connection
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
146
268
179
llm-enabled?
llm-enabled?
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
Prisoner 0 Score
player-score
17
1
11

MONITOR
695
170
785
215
Prisoner 1 Score
partner-score
17
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
LLM Enhanced Prisoner's Dilemma\n\nPrisoner 0 (left) uses LLM reasoning\nPrisoner 1 (right) uses simple strategy\n\nGreen = Cooperate (Silent)\nRed = Defect (Confess)\n\nClick 'Test API' before starting!
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

This is an enhanced version of the classic Prisoner's Dilemma that integrates Large Language Model (LLM) reasoning for strategic decision-making, following the patterns from the AntGPT Colony models.

You and your partner have been arrested for robbing a bank and find yourselves in the classic prisoner's dilemma. The police place each of you into separate rooms and come to you with the following proposal...

"We know you two did this, but don't have proof for anything but a minor charge of firearm possession that will give you a year of jail time. Confess to the robbery and we will make sure the judge goes easy on you, 3 years. If your partner confesses and you don't, we're going to throw the book at you and give you 5 years of prison time. If your partner doesn't and you do, we will let you go free."

### LLM Enhancement

Prisoner 0 (left) uses GPT-3.5-turbo to make decisions based on:
- Game history and partner's previous decisions
- Current trust level toward the partner
- Strategic reasoning about long-term implications
- JSON-formatted responses with decision and reasoning

Prisoner 1 (right) uses a simple tit-for-tat strategy or user-controlled decisions.

### Payoff Matrix

```text
 Your Action | Partner's Action | Your Jail Time | Partner's Jail Time
----------------------------------------------------------------------
   Silent          Silent               1                  1
   Silent          Confess              5                  0
   Confess         Silent               0                  5
   Confess         Confess              3                  3
```

## HOW TO USE IT

**SETUP**: Initialize the game with two prisoners and LLM integration. **IMPORTANT: Add your OpenAI API key in the setup-llm-integration procedure before running!**

**PLAY ROUND**: Execute one round of the prisoner's dilemma with LLM decision-making

**RESET GAME**: Clear all game history and start fresh

**LLM-ENABLED?**: Enable/disable LLM reasoning for Prisoner 0

**PARTNER-SILENCE-KNOWN?**: When on, allows controlling Prisoner 1's actions manually

**PARTNER-SILENT?**: Controls Prisoner 1's decision when partner-silence-known? is on

## LLM INTEGRATION

The model uses the Python extension to integrate with OpenAI's GPT-3.5-turbo model. The LLM receives context about:
- Current game number
- Partner's recent decision history
- Current scores for both prisoners
- Trust level toward partner

The LLM responds with JSON containing:
- Decision: "cooperate" or "defect"
- Reasoning: Strategic explanation
- Trust adjustment: How much to adjust trust level (-10 to +10)

## SETUP REQUIREMENTS

1. **NetLogo 6.4.0** or higher with Python extension
2. **Python** with openai package: `pip install openai`
3. **OpenAI API Key**: Replace 'Insert your API key here' in the setup-llm-integration procedure

## VISUAL FEEDBACK

- **Green prisoners**: Cooperating (staying silent)
- **Red prisoners**: Defecting (confessing)
- **Position**: Prisoner 0 (LLM) on left, Prisoner 1 (simple strategy) on right

## THINGS TO TRY

1. Run multiple rounds with LLM enabled and observe decision patterns
2. Compare LLM performance against different opponent strategies
3. Turn off LLM and compare pure strategy performance
4. Observe how trust levels evolve over time
5. Try different manual strategies using the partner controls

## EXTENDING THE MODEL

- Implement different opponent strategies
- Add more sophisticated trust dynamics
- Log complete game sessions for analysis
- Experiment with different LLM prompts
- Add multiple LLM agents competing

## TECHNICAL DETAILS

This model follows the same LLM integration pattern as the AntGPT Colony model:
- Python extension for LLM communication
- JSON parsing with error handling
- Structured prompt generation
- Robust fallback mechanisms

## NETLOGO FEATURES

- Python extension for LLM integration
- Breed-based modeling (prisoners)
- Dynamic visual feedback
- Real-time monitoring
- Error handling and logging

## RELATED MODELS

- AntGPT Colony (LLM integration pattern)
- PD Two Person Iterated
- PD N-Person Iterated
- PD Basic Evolutionary

## HOW TO CITE

If you mention this model in a publication, please cite:

* Enhanced Prisoner's Dilemma with LLM Integration (2025), based on AntGPT patterns
* Original: Wilensky, U. (2002). NetLogo Prisoner's Dilemma Basic model. http://ccl.northwestern.edu/netlogo/models/Prisoner'sDilemmaBasic

## COPYRIGHT AND LICENSE

Based on the original Prisoner's Dilemma Basic model by Uri Wilensky (2002)
Enhanced with LLM integration following AntGPT patterns
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
