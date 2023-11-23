# layout-optimizer
Some Julia code for making an optimized keyboard layout based on distance traveled by each finger
This code comes preconfigured to work with Colemak.

Install the following packages for your Julia environment (don't @ me because it's Julia, it was the original creator's handiwork which I've refactored)
- Plots
- BenchmarkTools
- EnumX

Change the layoutMap with your preferred finger positions and row positions for each key. I suggest changing the ColemakGenome to something else or creating your own to use; use those keys to fill in the layoutMap accurately.

While the code is running, it will spit out values for each generation. A new PNG will be created for each better generation than the last after a certain number of iterations.
Temperature is an arbitrary setting that will decrease over time, as will entropy of the objectives. The lower number is better. You ultimately want to aim to stop the simulation after your best iteration crosses into the negatives.
The included PNG is the best layout I could generate given a 6.5k word essay (MyBook.txt) of my writing. Let it run for as long as you want!

Have fun!
