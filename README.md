# Hermite

A highly optimized, type-strict module designed for graph functions and interpolation, custom easing equations, Bezier curves, and Hermite splines.

## 🛠️ API Reference

### Types

### `SplinePoint:{Point:number, Degree:number}`
Used in Hermite.Spline() as Points for both mentioning Y pos and strength.

### Core methods(70% of what you will need)

#### `Hermite.Linear(X: number, Start: number, End: number): number`
Performs a standard Lerp method between two numbers, returning t.
* `X`: Input (clamped between `0` and `1`).
* `Start`: The start value.
* `End`: The end value.

**Example:**
```
local Result = Hermite.Linear(0.5, 10, 20)
print(Result) -- 15
```

#### `Hermite.Sigmoid(X: number, Step: number?, Shift: number?): number`
Calculates a customizable through Step and Shift sigmoid function.
* `X`: Input (clamped between `0` and `1`).
* `Step`: The sharpness of the curve. Higher values mean steeper transitions. *Defaults to `1`*.
* `Shift`: The midpoint offset of the curve(where the curve is exactly t = 0.5). *Defaults to `0.5`*.

**Example:**
```
local A = Hermite.Sigmoid(0.69) --uses basic sigmoid
local B = Hermite.Sigmoid(0.8, 15, 0.8) --customized one
print(A, B) -- 0.666, 0.5
```

#### `Hermite.Bezier(X: number, Points: {number}, Order: boolean): number`
Evaluates a Bezier curve across a collection of control points.
* `X`: Input (clamped between `0` and `1`).
* `Points`: Array containing **2 to 5** control numeric positions. *(Note: feel free to redact binomial table and point-checking if you need more)*.
* `Order`: If `true`, the `Points` array will be pre-sorted in ascending order before calculation.

**Example:**
```
local Points = {0, 100, 20}
local A = Hermite.Bezier(0.5, Points, false)
local B = Hermite.Bezier(0.5, Points, true)
print(A, B) --55, 35
```

#### `Hermite.Spline(X: number, Points: {SplinePoint}, Order: boolean): number`
Calculates a Hermite spline across an array of key points.
* `X`: Input (clamped between `0` and `1`).
* `Points`: Array containing individual points. Must contain at least `2` entries.
* `Order`: If `true`, the `Points` array will be pre-sorted in ascending order before calculation.

**Example:**
```
local Points = {
    {Point = 0, Degree = 5},
    {Point = 10, Degree = 0},
    {Point = 0, Degree = -5}
}
local A = Hermite.Spline(0.5, Points, false)
local B = Hermite.Spline(1, Points, true)
print(A, B) --6.25, 0
```

---

### Custom Graphs(20% of what you will need)

#### `Hermite.Custom(X: number, Formula: (number) -> number, Check: boolean): number`
Executes a custom function on an input instantly without caching.
* `X`: Input.
* `Formula`: A callback function that manipulates and returns the result.
* `Check`: If `true`, clamps `X` to the `[0, 1]` range before passing it to the custom formula.

**Example:**
```
local A = Hermite.Custom(1.5, function(x) return x * 100 end, true)
local B = Hermite.Custom(1.5, function(x) return x * 100 end, false)
print(A, B) --100, 150
```

#### `Hermite.Sample<T>(Id: string, Formula: (number) -> T): number`
Registers a mathematical formula for future use.
* `Id`: Unique identifier for the custom graph.
* `Formula`: The mathematical function that will be pasted.

#### `Hermite.Evaluate<T>(Id: string, X: number): T`
Evaluates a previously registered custom graph by its identifier.
* `Id`: Unique identifier for the custom graph.
* `X`: Input.

#### `Hermite:Erase(Id: string): number`
Removes a custom graph from the registry.
* `Id`: The unique identifier for the custom graph.

**Example:**
```
Hermite.Sample("DoubleSquare", function(x) return (x^2)*2 end)
local Result = Hermite.Evaluate("DoubleSquare", 0.7)
print(Result) --0.98

Hermite.Erase("DoubleSquare")
print(Result) --! [Hermite]: Evaluate aborted: unable to find formula.
```

---

### Minor functions(10% of what you will need(you probably won't))

#### `Hermite.Step(X: number, Steps: number): number`
Snaps the coefficient into discrete incremental steps.
* `X`: Input.
* `Steps`: The resolution threshold.

**Example:**
```
local Result = Hermite.Step(0.3, 4)
print(Result) --0.25
```

#### `Hermite.DefineWarn(Warn: boolean): number`
Enables or disables standard output warnings(toggled off by default).
* `Warn`: Toggles warn reporting.
I don't really think this needs an example ;-;

#### `Hermite.Bake(Method: string, Resolution: number, Decode: boolean, ...: any): {number} | buffer`
Repeats the same method for `Resolution` times, returning a buffer(or array if Decode: true) of every calculated value ascending.
Make sure to paste correct arguments in `...` for method you will be using. Those include: `Sigmoid`, `Linear`, `Bezier`, `Spline`, `Step`.
* `Method`: Name of function that will be repeated.
* `Resolution`: How many times will `Method` be repeated.
* `Decode`: Whether `Bake` should return an array of a buffer.
* `...`: Arguments needed for the method.

**Example:**
```
local Result = Hermite.Bake("Linear", 4, true, 0, 100)

print(Result[1]) --0
print(Result[3]) --0.5
print(Result[5]) --1
```
