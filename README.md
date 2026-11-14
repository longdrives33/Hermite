# Hermite

A highly optimized, type-strict module designed for graph functions and interpolation, custom easing equations, Bezier curves, and Hermite splines.

## 🛠️ API Reference

## SMALL NOTES
* Most of the scripts either upon error, either if they don't need to return any value(These being `Sample`, `Erase` and `DefineWarn`) will always return 0.

### 📈 Core methods(70% of what you will need)

#### `Hermite:Linear(X: number, Start: number, End: number): number`
Performs a standard Lerp method between two numbers, returning t.
* `X`: Input (clamped between `0` and `1`).
* `Start`: The start value.
* `End`: The end value.

#### `Hermite:Sigmoid(X: number, Step: number?, Shift: number?): number`
Calculates a customizable through Steo and Shift sigmoid function.
* `X`: Input (clamped between `0` and `1`).
* `Step`: The sharpness of the curve. Higher values mean steeper transitions. *Defaults to `1`*.
* `Shift`: The midpoint offset of the curve(where the curve is exactly t = 0.5). *Defaults to `0.5`*.

#### `Hermite:Bezier(X: number, Points: {number}, Order: boolean): number`
Evaluates a Bezier curve across a collection of control points.
* `X`: Input (clamped between `0` and `1`).
* `Points`: Array containing **2 to 5** control numeric positions. *(Note: feel free to redact binomial table and point-checking if you need more)*.
* `Order`: If `true`, the `Points` array will be pre-sorted in ascending order before calculation.

#### `Hermite:Spline(X: number, Points: {SplinePoint}, Order: boolean): number`
Calculates a Hermite spline across an array of key points.
* `X`: Input (clamped between `0` and `1`).
* `Points`: Array containing individual points. Must contain at least `2` entries.
* `Order`: If `true`, the `Points` array will be pre-sorted in ascending order before calculation.

---

### 🎭 Built-in and custom graphs(15% of what you will need)

#### `Hermite:Graph(X: number, Type: Enum.EasingStyle, Way: Enum.EasingDirection): number`
Evaluates standard Roblox Easing Styles.
* `X`: Input (clamped between `0` and `1`).
* `Type`: Supports standard easing equations except `Spring` and `None`.
* `Way`: Direction of the curve.

#### `Hermite:Custom(X: number, Formula: (number) -> number, Check: boolean): number`
Executes a custom function on an input instantly without caching.
* `X`: Input.
* `Formula`: A callback function that manipulates and returns the result.
* `Check`: If `true`, clamps `X` to the `[0, 1]` range before passing it to the custom formula.

---

### 💾 Custom Graphs(10% of what you will need)

#### `Hermite:Sample<T>(Id: string, Formula: (number) -> T): number`
Registers a mathematical formula for future use.
* `Id`: Unique identifier for the custom graph.
* `Formula`: The mathematical function that will be pasted.

#### `Hermite:Evaluate<T>(Id: string, X: number): T`
Evaluates a previously registered custom graph by its identifier.
* `Id`: Unique identifier for the custom graph.
* `X`: Input.

#### `Hermite:Erase(Id: string): number`
Removes a custom graph from the registry.
* `Id`: The unique identifier for the custom graph.

---

### ⚙️ Minor functions(5% of what you will need(you probably won't))

#### `Hermite:Step(X: number, Steps: number): number`
Snaps the coefficient into discrete incremental steps.
* `X`: Input.
* `Steps`: The resolution threshold.

#### `Hermite:DefineWarn(Warn: boolean): number`
Enables or disables standard output warnings(toggled off by default).
* `Warn`: Toggles warn reporting.
