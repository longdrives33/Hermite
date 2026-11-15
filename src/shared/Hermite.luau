--!optimize 2
--!strict
local Hermite = {}
local doWarn = false
local BezCPunder = 2
local BezCPabove = 5
local CMCPunder = 2
local OLSCPunder = 2
local BakeLimit = 268_000_000

export type SplinePoint = {
    Point:number,
    Degree:number
}

export type genCG<T> = {
    [string]: (number)->(T)
}

local function xCheck(X:number, Above:boolean):number
    if not doWarn then
        return math.clamp(X, 0, 1)
    end
    if X > 1 and Above then
        warn("[Hermite]: X exceeds the supported range [0, 1]; clamped to 1.")
        return 1
    elseif X < 0 then
        warn("[Hermite]: X is below the supported range [0, 1]; clamped to 0.")
        return 0
    end
    return X
end

local BinomialTable:{[number]: {[number]: number}} = { -- calculated by: !x * !y / !(x - y)
    [1] = {
        [0] = 1,
        [1] = 1
    },
    [2] = {
        [0] = 1,
        [1] = 2,
        [2] = 1
    },
    [3] = {
        [0] = 1,
        [1] = 3,
        [2] = 3,
        [3] = 1
    },
    [4] = {
        [0] = 1,
        [1] = 4,
        [2] = 6,
        [3] = 4,
        [4] = 1
    },
    [5] = {
        [0] = 1,
        [1] = 5,
        [2] = 10,
        [3] = 10,
        [4] = 5,
        [5] = 1
    }
}

function Hermite.Sigmoid(X:number, Step:number?, Shift:number?):number --x is num, shift is middle point(x=0.5 always there) and step is sharpness(the higher, the sharper)
    X = xCheck(X, true)
    local cStep = Step or 1
    local cShift = Shift or 0.5
    return 1 / (1 + math.exp(-cStep * (X - cShift)))
end

function Hermite.Linear(X:number, Start:number, End:number):number
    X = xCheck(X, true)
    return Start + (End - Start) * X
end

function Hermite.Bezier(X:number, Points:{number}, Order:boolean?):number
    local tPoints = Points
    if Order then
        table.sort(tPoints)
    end
    X = xCheck(X, true)
    local count = #tPoints
    if count < BezCPunder or count > BezCPabove then --bezier limits. You can change them if you want. Change BinomialTable then aswell.
        if doWarn then
            warn(`! [Hermite]: Bezier aborted: expected {BezCPunder}-{BezCPabove} control points.`)
        end
        return 0
    end
    local n = count - 1
    local bin = BinomialTable[n]
    local Final = 0
    local av1 = 1 - X

    for i = 0, n do
        local point = tPoints[i + 1]
        local weight = bin[i] * ((av1)^(n - i)) * (X^i)

        Final += point * weight
    end

    return Final
end

local CustomGraphs : genCG<unknown> = {}

function Hermite.Custom(X:number, Formula:(number)->number, Check:boolean):number
    local res = X
    if Check then
        res = xCheck(X, true)
    end
    return Formula(res)
end

function Hermite.Sample<T>(Id:string, Formula:(number)->T):()
    CustomGraphs[Id] = Formula :: (number)->unknown
    return
end

function Hermite.Evaluate<T>(Id:string, X:number):T
    local Formula = CustomGraphs[Id]
    if not Formula then
        if doWarn then
            warn("! [Hermite]: Evaluate aborted: unable to find formula.")
        end
        return nil :: any
    end
    return (Formula::(number)->T)(X)
end

function Hermite.Erase(Id:string):()
    CustomGraphs[Id] = nil
    return
end

function Hermite.Spline(X:number, Points:{SplinePoint}, Order:boolean):number
    local tPoints = Points
    if Order then
        table.sort(tPoints, function(a, b)
            return a.Point < b.Point
        end)
    end
    local xc = xCheck(X, false)
    local Segments = #tPoints - 1
    if Segments < 1 then
        if doWarn then
            warn("! [Hermite]: Spline aborted: expected atleast 2 points.")
        end
        return 0
    end
    local t = math.clamp(xc, 0, Segments)

    local Part = math.floor(t) + 1
    if Part > Segments then
        Part = Segments
    end
    local part2 = Part + 1
    local CurrentT = t > Segments and 1 or (t - (Part - 1))

    local p0 = tPoints[Part].Point
    local p1 = tPoints[part2].Point
    local d0 = tPoints[Part].Degree
    local d2 = tPoints[part2].Degree

    local t2 = CurrentT*CurrentT
    local t3 = t2*CurrentT

    local h0 = 2 * t3 - 3 * t2 + 1
    local h1 = -2 * t3 + 3 * t2
    local h2 = t3 - 2 * t2 + CurrentT
    local h3 = t3 - t2
    return p0 * h0 + d0 * h2 + p1 * h1 + d2 * h3
end

function Hermite.DefineWarn(Warn:boolean):()
    doWarn = Warn
    return
end

function Hermite.Step(X:number, Steps:number):number
    if Steps == 0 then
        if doWarn then
            warn("! [Hermite]: Step aborted: given value was zero, interrupting division.")
        end
        return 0
    end
    return math.floor(X * Steps) / Steps
end

local Bakeable : {[string]:(number, ...any)->number} = {
    ["Sigmoid"] = Hermite.Sigmoid,
    ["Linear"] = Hermite.Linear,
    ["Bezier"] = Hermite.Bezier,
    ["Spline"] = Hermite.Spline,
    ["Step"] = Hermite.Step
}

function Hermite.Bake(Method:string, Resolution:number, Decode:boolean, ...:any):{number} | buffer
    local fn = Bakeable[Method]
    if not fn then
        if doWarn then
            warn(`! [Hermite]: Bake aborted: {Method} is not a valid Hermite function.`)
        end
        return {}
    end
    local steps = math.max(1, Resolution)
    steps = math.min(Resolution, BakeLimit)
    local buf = buffer.create((steps + 1) * 4)
    local Result:{number} = {}
    local x = 0
    local y = 0
    for i = 0, steps do
        x = i / steps
        y = fn(x, ...)
        buffer.writef32(buf, i * 4, y)
        Result[i] = y
    end
    return Decode == true and Result or buf
end

function Hermite.OLS(Points:{vector}):(number, number)
    local count = #Points
    if count < OLSCPunder then
        if doWarn then
            warn(`! [Hermite]: OLS aborted. Expected more than {OLSCPunder} control points.`)
        end
        return 0, 0
    end
    local sumX, sumY = 0,0
    for _, p in Points do
        sumX += p.x
        sumY += p.y
    end
    local mx = sumX / count
    local my = sumY / count

    local num, dem = 0,0

    for _, p in Points do
        local dx = p.x - mx
        local dy = p.y - my
        num += dx * dy
        dem += dx * dx
    end

    if dem == 0 then --in this case its noy your fault of input but rather you've written points in a specific input so dem somehow is 0(prob cuz all points are the same or idk). Make sure to recheck your calculations.
        if doWarn then
            warn("! [Hermite]: OLS aborted. Your points have probably the same input(Please check lines 223-260 for more info).")
        end
        return 0, 0
    end
    local slope = num / dem
    local interc = my - slope * mx
    
    return slope, interc
end

local function catmull(p0:vector, p1:vector, p2:vector, p3:vector, t:number): vector
    local t2 = t*t
    local t3 = t2*t

    return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
end

function Hermite.Catmull(X:number, Points:{vector}):vector
    local count = #Points
    X = xCheck(X, true)
    if count < CMCPunder then
        if doWarn then
            warn(`! [Hermite]: OLS aborted. Expected more than {CMCPunder} control points.`)
        end
        return vector.zero
    end

    local segm = count - 1
    local sc = X * segm
    local i = math.min(math.floor(sc) + 1, segm)
    local si = i - 1
    local t = sc - (si)

    local p0 = Points[math.max(si, 1)]
    local p1 = Points[i]
    local p2 = Points[i + 1]
    local p3 = Points[math.min(i + 2, count)]
    
    return catmull(p0, p1, p2, p3, t)
end

return Hermite