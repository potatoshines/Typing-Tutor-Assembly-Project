# Typing-Tutor-Assembly-Project
A console-based typing tutor project built in Assembly language, designed to help users improve typing through practice typing test as well as an interactive, falling-words gameplay experience.

## Features
- **Two Typing Modes**: Text-based typing practice and an interactive falling-words game mode
- **Interactive Gameplay**: Words fall from the top of the console, and players must type them before they hit the ground.
- **Speed Tracking & Accuracy Metrics**: Calculates Words Per Minute (WPM) as well as ACCURACY
- **Customizable Settings**: Easily modify row spacing and word drop intervals, as well as the number of words

## Technologies
- **Assembly Language**: Core gameplay logic and algorithms implemented in Assembly.
- **Irvine32 Library**: Provides essential functions for input/output operations and system interactions
- **MASM (Microsoft Macro Assembler)**: Used for assembling and linking the program, leveraging its robust support for x86 architecture.
- **x86 Interrupts**: Directly manages console manipulation, timing, and input/output operations for smooth performance.

## How It Works
1. **Falling Words**: Words appear at random positions and move down the screen.
2. **Typing Interaction**: Users must match and type the falling words correctly to remove them before they reach the ground.
3. **Performance Tracking**: The program calculates WPM and accuracy, rewarding quick and accurate typing.
4. **Missed Words**: If words are not typed in time, they are counted as misses.
5. **Word Priority**: Targets the word based on the user's first character input first, as well as their row positions (bottom-most word goes first).

## Demo Video
Pending
