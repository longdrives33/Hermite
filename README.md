# Hermite

A highly optimized, type-strict **Luau** module designed for mathematical interpolation, custom easing equations, Bezier curves, and cubic Hermite splines. 

## ✨ Features
* 🚀 **Performance Optimized:** Uses localized math globals (`math.sin`, `math.exp`, etc.) and native Luau `--!optimize 2` performance flags.
* 🛡️ **Type Safe:** Fully typed with strict Luau (`--!strict`) structural components.
* 🛑 **Bound Validation:** Built-in configurable boundary safeguards for numerical alpha parameters (`[0, 1]` clamping).

---

## 📋 Data Types

### `SplinePoint`
Represents a structural node used within the cubic spline calculator.
* **`Point`**: `number` — The positional value (height/coordinate) of the node.
* **`Degree`**: `number` — The tangent (velocity/slope) at this specific node.

---

## 🛠️ API Reference

### `Hermite:Sigmoid(X: number, Step: number?, Shift: number?): number`
Calculates a standard logistic sigmoid function curve. Useful for smooth acceleration/deceleration thresholds.
* `X`: Input factor (clamped between `0` and `1`).
* `Step`: The sharpness/slope of the curve. Higher values mean steeper transitions. *Defaults to `1`*.
* `Shift`: The midpoint offset of the curve. *Defaults to `0.5`*.

### `Hermite:Linear(X: number, Start: number, End: number): number`
Performs a standard Linear Interpolation (Lerp) between two numbers.
* `X`: The interpolation alpha factor (clamped between `0` and `1`).
* `Start`: The beginning boundary value.
* `End`: The ending boundary value.

### `Hermite:Bezier(X: number, Points: {number}, Order: boolean): number?`
Evaluates a Bezier curve across a collection of control points using pre-calculated binomial coefficients.
* `X`: The progression step (clamped between `0` and `1`).
* `Points`: Array containing **2 to 5** control numeric positions.
* `Order`: If `true`, the `Points` array will be pre-sorted in ascending order before calculation.

### `Hermite:Graph(X: number, Type: Enum.EasingStyle, Way: Enum.EasingDirection): number?`
Evaluates standard Roblox Easing Styles mathematically for custom programmatic interpolation.
* `X`: Time progression coefficient (clamped between `0` and `1`).
* `Type`: Supports standard easing equations (`Linear`, `Sine`, `Quad`, `Cubic`, `Quart`, `Quint`, `Exponential`, `Circular`, `Back`, `Elastic`, `Bounce`).
* `Way`: Direction of the easing curve (`In`, `Out`, `InOut`).

### `Hermite:Custom(X: number, Formula: (number) -> number, Check: boolean): number`
Executes a custom mathematically mapped function on an alpha factor.
* `X`: The transition factor.
* `Formula`: A callback function designed to manipulate and return the numeric factor.
* `Check`: If `true`, clamps `X` to the `[0, 1]` range before passing it to the custom formula.

### `Hermite:Spline(X: number, Points: {SplinePoint}, Order: boolean): number?`
Calculates a localized Cubic Hermite Spline across a series of structured key points.
* `X`: Global time progression along the entire spline duration sequence.
* `Points`: Array containing individual `SplinePoint` nodes. Must contain at least `2` entries.
* `Order`: If `true`, the `Points` array will be pre-sorted before resolving segments.

### `Hermite:Step(X: number, Steps: number): number`
Snaps a float coefficient into discrete incremental steps. Useful for quantized configurations or cel-shaded UI visual effects.
* `X`: The raw value.
* `Steps`: The resolution threshold count.

### `Hermite:DefineWarn(Warn: boolean): boolean`
Enables or disables standard output configuration warnings generated when inputs exceed standard boundaries or constraints.
* `Warn`: Toggles library warning reporting.

---
