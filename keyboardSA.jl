# ### SETUP ###
# ~~~ libraries ~~~
using Plots
using Random
using Base.Threads
using BenchmarkTools
using Statistics
using EnumX

# ~~~ data ~~~
bookPath = "MyBook.txt"

# ~~~ weights ~~~
distanceEffort = 1.2 # at 2 distance penalty is squared
doubleFingerEffort = 1
doubleHandEffort = 1 

@enumx Hands begin
	Left  = 1
	Right = 2
end

@enumx Fingers begin
	LeftPinky   = 1
	LeftRing    = 2
	LeftMiddle  = 3
	LeftIndex   = 4
	RightIndex  = 5
	RightMiddle = 6
	RightRing   = 7
	RightPinky  = 8
end

@enumx KeyboardRows begin
	Numbers = 1
	Top     = 2
	Middle  = 3
	Bottom  = 4
end

handList = [Int(Hands.Left),  Int(Hands.Left),  Int(Hands.Left),  Int(Hands.Left), 
            Int(Hands.Right), Int(Hands.Right), Int(Hands.Right), Int(Hands.Right)]

fingerCPM = [223, 169, 225, 273, 343, 313, 259, 241] # how many clicks can you do in a minute
meanCPM = mean(fingerCPM)
stdCPM = std(fingerCPM)
zScoreCPM = -(fingerCPM .- meanCPM) ./ stdCPM # negative since higher is better
fingerEffort = zScoreCPM .- minimum(zScoreCPM)

rowCPM = [131, 166, 276, 192]
meanCPM = mean(rowCPM)
stdCPM = std(rowCPM)
zScoreCPM = -(rowCPM .- meanCPM) ./ stdCPM # negative since higher is better
rowEffort = zScoreCPM .- minimum(zScoreCPM)

effortWeighting = [0.7917, 1, 0, 0.4773, 0.00] # dist, finger, row. Also had room for other weightings but removed for simplicity

# ~~~ keyboard ~~~
# Adjust these based on your typing preference
# (x, y, row, finger, home)
layoutMap = Dict(
    1 =>  [ 0.50, 4.5, Int(KeyboardRows.Numbers), Int(Fingers.LeftRing   ), 0], # ~
    2 =>  [ 1.50, 4.5, Int(KeyboardRows.Numbers), Int(Fingers.LeftRing   ), 0], # 1
    3 =>  [ 2.50, 4.5, Int(KeyboardRows.Numbers), Int(Fingers.LeftRing   ), 0], # 2
    4 =>  [ 3.50, 4.5, Int(KeyboardRows.Numbers), Int(Fingers.LeftMiddle ), 0], # 3
    5 =>  [ 4.50, 4.5, Int(KeyboardRows.Numbers), Int(Fingers.LeftMiddle ), 0], # 4
    6 =>  [ 5.50, 4.5, Int(KeyboardRows.Numbers), Int(Fingers.LeftIndex  ), 0], # 5
    7 =>  [ 6.50, 4.5, Int(KeyboardRows.Numbers), Int(Fingers.LeftIndex  ), 0], # 6
    8 =>  [ 7.50, 4.5, Int(KeyboardRows.Numbers), Int(Fingers.RightIndex ), 0], # 7
    9 =>  [ 8.50, 4.5, Int(KeyboardRows.Numbers), Int(Fingers.RightMiddle), 0], # 8
    10 => [ 9.50, 4.5, Int(KeyboardRows.Numbers), Int(Fingers.RightMiddle), 0], # 9
    11 => [10.50, 4.5, Int(KeyboardRows.Numbers), Int(Fingers.RightRing  ), 0], # 0
    12 => [11.50, 4.5, Int(KeyboardRows.Numbers), Int(Fingers.RightRing  ), 0], # -
    13 => [12.50, 4.5, Int(KeyboardRows.Numbers), Int(Fingers.RightRing  ), 0], # +
    14 => [ 2.00, 3.5, Int(KeyboardRows.Top    ), Int(Fingers.LeftRing   ), 0], # Q
    15 => [ 3.00, 3.5, Int(KeyboardRows.Top    ), Int(Fingers.LeftRing   ), 0], # W
    16 => [ 4.00, 3.5, Int(KeyboardRows.Top    ), Int(Fingers.LeftMiddle ), 0], # F
    17 => [ 5.00, 3.5, Int(KeyboardRows.Top    ), Int(Fingers.LeftIndex  ), 0], # P
    18 => [ 6.00, 3.5, Int(KeyboardRows.Top    ), Int(Fingers.LeftIndex  ), 0], # G
    19 => [ 7.00, 3.5, Int(KeyboardRows.Top    ), Int(Fingers.RightIndex ), 0], # J
    20 => [ 8.00, 3.5, Int(KeyboardRows.Top    ), Int(Fingers.RightIndex ), 0], # L
    21 => [ 9.00, 3.5, Int(KeyboardRows.Top    ), Int(Fingers.RightMiddle), 0], # U
    22 => [10.00, 3.5, Int(KeyboardRows.Top    ), Int(Fingers.RightRing  ), 0], # Y
    23 => [11.00, 3.5, Int(KeyboardRows.Top    ), Int(Fingers.RightPinky ), 0], # ;
    24 => [12.00, 3.5, Int(KeyboardRows.Top    ), Int(Fingers.RightIndex ), 0], # [
    25 => [13.00, 3.5, Int(KeyboardRows.Top    ), Int(Fingers.RightMiddle), 0], # ]
    26 => [ 2.25, 2.5, Int(KeyboardRows.Middle ), Int(Fingers.LeftPinky  ), 1], # A
    27 => [ 3.25, 2.5, Int(KeyboardRows.Middle ), Int(Fingers.LeftRing   ), 1], # R
    28 => [ 4.25, 2.5, Int(KeyboardRows.Middle ), Int(Fingers.LeftMiddle ), 1], # S
    29 => [ 5.25, 2.5, Int(KeyboardRows.Middle ), Int(Fingers.LeftIndex  ), 1], # T
    30 => [ 6.25, 2.5, Int(KeyboardRows.Middle ), Int(Fingers.LeftIndex  ), 0], # D
    31 => [ 7.25, 2.5, Int(KeyboardRows.Middle ), Int(Fingers.RightIndex ), 0], # H
    32 => [ 8.25, 2.5, Int(KeyboardRows.Middle ), Int(Fingers.RightIndex ), 1], # N
    33 => [ 9.25, 2.5, Int(KeyboardRows.Middle ), Int(Fingers.RightMiddle), 1], # E
    34 => [10.25, 2.5, Int(KeyboardRows.Middle ), Int(Fingers.RightRing  ), 1], # I
    35 => [11.25, 2.5, Int(KeyboardRows.Middle ), Int(Fingers.RightPinky ), 1], # O
    36 => [12.25, 2.5, Int(KeyboardRows.Middle ), Int(Fingers.RightPinky ), 0], # '
    37 => [ 2.75, 1.5, Int(KeyboardRows.Bottom ), Int(Fingers.LeftPinky  ), 0], # Z
    38 => [ 3.75, 1.5, Int(KeyboardRows.Bottom ), Int(Fingers.LeftRing   ), 0], # X
    39 => [ 4.75, 1.5, Int(KeyboardRows.Bottom ), Int(Fingers.LeftMiddle ), 0], # C
    40 => [ 5.75, 1.5, Int(KeyboardRows.Bottom ), Int(Fingers.LeftIndex  ), 0], # V
    41 => [ 6.75, 1.5, Int(KeyboardRows.Bottom ), Int(Fingers.LeftIndex  ), 0], # B
    42 => [ 7.75, 1.5, Int(KeyboardRows.Bottom ), Int(Fingers.RightIndex ), 0], # K
    43 => [ 8.75, 1.5, Int(KeyboardRows.Bottom ), Int(Fingers.RightIndex ), 0], # M
    44 => [ 9.75, 1.5, Int(KeyboardRows.Bottom ), Int(Fingers.RightMiddle), 0], # <
    45 => [10.75, 1.5, Int(KeyboardRows.Bottom ), Int(Fingers.RightPinky ), 0], # >
    46 => [11.75, 1.5, Int(KeyboardRows.Bottom ), Int(Fingers.RightPinky ), 0], # ?
)

#Adjust/rename this based on your preferred keyboard layout.
ColemakGenome = [
  "~", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "+", 
	"Q", "W", "F", "P", "G", "J", "L", "U", "Y", ";", "[", "]",
	 "A", "R", "S", "T", "D", "H", "N", "E", "I", "O", "'",
          "Z", "X", "C", "V", "B", "K", "M", "<", ">", "?"
]

# alphabet
letterList = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",
    "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V",
    "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6",
    "7", "8", "9", "~", "-", "+", "[", "]", ";", "'", "<",
    ">", "?"
]

# map dictionary
keyMapDict = Dict(
    'a' => [1,0],  'A' => [1,1],  'b' => [2,0],  'B' => [2,1],
    'c' => [3,0],  'C' => [3,1],  'd' => [4,0],  'D' => [4,1],
    'e' => [5,0],  'E' => [5,1],  'f' => [6,0],  'F' => [6,1],
    'g' => [7,0],  'G' => [7,1],  'h' => [8,0],  'H' => [8,1],
    'i' => [9,0],  'I' => [9,1],  'j' => [10,0], 'J' => [10,1],
    'k' => [11,0], 'K' => [11,1], 'l' => [12,0], 'L' => [12,1],
    'm' => [13,0], 'M' => [13,1], 'n' => [14,0], 'N' => [14,1],
    'o' => [15,0], 'O' => [15,1], 'p' => [16,0], 'P' => [16,1],
    'q' => [17,0], 'Q' => [17,1], 'r' => [18,0], 'R' => [18,1],
    's' => [19,0], 'S' => [19,1], 't' => [20,0], 'T' => [20,1],
    'u' => [21,0], 'U' => [21,1], 'v' => [22,0], 'V' => [22,1],
    'w' => [23,0], 'W' => [23,1], 'x' => [24,0], 'X' => [24,1],
    'y' => [25,0], 'Y' => [25,1], 'z' => [26,0], 'Z' => [26,1],
    '0' => [27,0], ')' => [27,1], '1' => [28,0], '!' => [28,1],
    '2' => [29,0], '@' => [29,1], '3' => [30,0], '#' => [30,1],
    '4' => [31,0], '$' => [31,1], '5' => [32,0], '%' => [32,1],
    '6' => [33,0], '^' => [33,1], '7' => [34,0], '&' => [34,1],
    '8' => [35,0], '*' => [35,1], '9' => [36,0], '(' => [36,1],
    '`' => [37,0], '~' => [37,1], '-' => [38,0], '_' => [38,1],
    '=' => [39,0], '+' => [39,1], '[' => [40,0], '{' => [40,1],
    ']' => [41,0], '}' => [41,1], ';' => [42,0], ':' => [42,1],
    "'" => [43,0], '"' => [43,1], ',' => [44,0], '<' => [44,1],
    '.' => [45,0], '>' => [45,1], '/' => [46,0], '?' => [46,1]
)

# ### KEYBOARD FUNCTIONS ###
function createGenome()
    # setup
    myGenome = shuffle(letterList)

    # return
    return myGenome
end

function drawKeyboard(myGenome, id)
    plot()
    namedColours = ["yellow", "blue", "green", "orange", "pink", "green", "blue", "yellow"]

    for i in 1:46
        letter = myGenome[i]
        x, y, row, finger, home = layoutMap[i]
        # myColour = namedColours[Int(finger)]

        myColour = "gray69"
        if letter in ["A","R","S","T","N","E","I","O"]
            myColour = "springgreen2" 
        elseif letter in ["D", "H", "W", "L", "V", "P"]
            myColour = "green" 
        elseif letter in ["K", "M", "U", "Q", "Y","~"]
            myColour = "darkgreen" 
        elseif letter in ["[", "]", "+", "7", "4", "6", "3", "8", "5","J"]
            myColour = "tomato"
        end

        if home == 1.0
            plot!([x], [y], shape=:rect, fillalpha=0.2, linecolor=nothing, color = myColour, label ="", markersize= 16.5 , dpi = 100)
        end
        
        plot!([x - 0.45, x + 0.45, x + 0.45, x - 0.45, x - 0.45], [y - 0.45, y - 0.45, y + 0.45, y + 0.45, y - 0.45], color = myColour, fillalpha = 0.2, label ="", dpi = 100)
        
        annotate!(x, y, text(letter, :black, :center, 10))
    end
    
    plot!(aspect_ratio = 1, legend = false)
    savefig("$(Int(id)).png")

end

function countCharacters()
    char_count = Dict{Char, Int}()
    
    # Open the file for reading
    io = open(bookPath, "r")
    
    # Read each line from the file
    for line in eachline(io)
        for char in line
            char = uppercase(char)
            char_count[char] = get(char_count, char, 0) + 1
        end
    end
    
    # Close the file
    close(io)
    
    return char_count
end

# ### SAVE SCORE ###
function appendUpdates(updateLine)
    file = open("iterationScores.txt", "a")
    write(file, updateLine, "\n")
    close(file)
end

# ### OBJECTIVE FUNCTIONS ###
function determineKeypress(currentCharacter)
    # setup
    keyPress = "NONE"

    # proceed if valid key (e.g. we dont't care about spaces now)
    if haskey(keyMapDict, currentCharacter)
        keyPress, _ = keyMapDict[currentCharacter]
    end
   
    # return
    return keyPress
end

function doKeypress(myFingerList, myGenome, keyPress, oldFinger, oldHand)
    # setup
    # ~ get the key being pressed ~
    namedKey = letterList[keyPress]
    actualKey = findfirst(x -> x == namedKey, myGenome)

    # ~ get its location ~
    x, y, row, finger, home = layoutMap[actualKey]
    currentHand = handList[Int(finger)]
    
    # loop through fingers
    for fingerID in 1:8
        # load
        homeX, homeY, currentX, currentY, distanceCounter, objectiveCounter = myFingerList[fingerID,:]

        if fingerID == finger # move finger to key and include penalty
            # ~ distance
            distance = sqrt((x - currentX)^2 + (y - currentY)^2)

            distancePenalty = distance^distanceEffort # i.e. squared
            newDistance = distanceCounter + distance

            # ~ double finger ~
            doubleFingerPenalty = 0
            if finger != oldFinger && oldFinger != 0 && distance != 0
                doubleFingerPenalty = doubleFingerEffort
            end
            oldFinger = finger


            # ~ double hand ~
            doubleHandPenalty = 0
            if currentHand != oldHand && oldHand != 0
                doubleHandPenalty = doubleHandEffort
            end
            oldHand = currentHand

            # ~ finger
            fingerPenalty = fingerEffort[fingerID]

            # ~ row
            rowPenalty = rowEffort[Int(row)]

            # ~ combined weighting
            penalty = sum([distancePenalty, doubleFingerPenalty, doubleHandPenalty, fingerPenalty, rowPenalty] .* effortWeighting)
            newObjective = objectiveCounter + penalty

            # ~ save
            myFingerList[fingerID, 3] = x
            myFingerList[fingerID, 4] = y
            myFingerList[fingerID, 5] = newDistance
            myFingerList[fingerID, 6] = newObjective
        else # re-home unused finger
            myFingerList[fingerID, 3] = homeX
            myFingerList[fingerID, 4] = homeY
        end
    end

    # return
    return myFingerList, oldFinger, oldHand
end

function objectiveFunction(myGenome, baseline)
    # setup
    objective = 0
   
    # ~ create hand ~
    myFingerList = zeros(8, 6) # (homeX, homeY, currentX, currentY, distanceCounter, objectiveCounter)

    for i in 1:46
        x, y, _, finger, home = layoutMap[i]

        if home == 1.0
            myFingerList[Int(finger), 1:4] = [x, y, x, y]
        end
    end
    
    # load text
    file = open(bookPath, "r")
    oldFinger = 0
    oldHand = 0

    try
        while !eof(file)
            currentCharacter = read(file, Char)

            # determine keypress
            keyPress = determineKeypress(currentCharacter)

            # do keypress
            if keyPress != "NONE"
                myFingerList, oldFinger, oldHand = doKeypress(myFingerList, myGenome, keyPress, oldFinger, oldHand)
            end
        end
    finally
        close(file)
    end

    # calculate objective
    objective = sum(myFingerList[:, 6])
		if (baseline == false)
			objective = (objective / ColemakScore - 1) * 100
		end

    # return
    return objective
end

# ### SA OPTIMIZER ###
function shuffleGenome(currentGenome, temperature)
    # setup
    noSwitches = Int(maximum([2, minimum([floor(temperature/100), 46])]))

    # positions of switched letterList
    switchedPositions = randperm(46)[1:noSwitches]
    newPositions = shuffle(copy(switchedPositions))

    # create new genome by shuffling
    newGenome = copy(currentGenome)
    for i in 1:noSwitches
        og = switchedPositions[i]
        ne = newPositions[i]

        newGenome[og] = currentGenome[ne]
    end

    return newGenome

end


function runSA()
		println("This code will determine a better layout than the one given...hopefully.")
    print("Calculating raw baseline: ")
    global ColemakScore = objectiveFunction(ColemakGenome,true)
    println(ColemakScore)
    println("From here everything is relative with + % worse and - % better than this baseline \n Note that the best layout is being saved as a png at each step. Kill the program when satisfied.")
    println("Temperature \t Best Score \t New Score")

    # setup
    currentGenome = createGenome()
    currentObjective = objectiveFunction(currentGenome,false)

    bestGenome = currentGenome
    bestObjective = currentObjective

    temperature  = 500
    epoch = 20
    coolingRate = 0.99
    num_iterations = 25000
    drawKeyboard(bestGenome, 0)

    # run SA
    staticCount = 0.0
    for iteration in 1:num_iterations
        # ~ create new genome ~
        newGenome = shuffleGenome(currentGenome, 2)

        # ~ assess ~
        newObjective = objectiveFunction(newGenome,false)
        delta = newObjective - currentObjective

        println(round(temperature, digits = 2), "\t", round(bestObjective, digits=2), "\t", round(newObjective, digits=2))

        if delta < 0
            currentGenome = copy(newGenome)
            currentObjective = newObjective

            updateLine = string(round(temperature, digits = 2), ", ",  iteration, ", ", round(bestObjective, digits=5), ", ", round(newObjective, digits=5))
            appendUpdates(updateLine)

            if newObjective < bestObjective
                bestGenome = newGenome
                bestObjective = newObjective

                #staticCount = 0.0

                println("(new best, png being saved)")
                

                drawKeyboard(bestGenome, iteration)
            end
        elseif exp(-delta/temperature) > rand()
            #print(" *")
            currentGenome = newGenome
            currentObjective = newObjective
        end

        staticCount += 1.0

        if staticCount > epoch
            staticCount = 0.0
            temperature = temperature * coolingRate

            if rand() < 0.5
                currentGenome = bestGenome
                currentObjective = bestObjective
            end
        end
    end

    # save
    drawKeyboard(bestGenome, "final")

    # return
    return bestGenome

end

# ### RUN ###
runSA()
