## Surrogates 101
Let's start with something easy to get our hands dirty.
I want to build a surrogate for ``f(x) = log(x)*x^2+x^3``.
Let's choose the radial basis surrogate.
```@example
using Surrogates
f = x -> log(x)*x^2+x^3
lb = 1.0
ub = 10.0
x = sample(50,lb,ub,SobolSample())
y = f.(x)
my_radial_basis = RadialBasis(x,y,lb,ub,rad=thinplateRadial)

#I want an approximation at 5.4
approx = my_radial_basis(5.4)
```
Let's now see an example in 2D.
```@example
using Surrogates
using LinearAlgebra
f = x -> x[1]*x[2]
lb = [1.0,2.0]
ub = [10.0,8.5]
x = sample(50,lb,ub,SobolSample())
y = f.(x)
my_radial_basis = RadialBasis(x,y,lb,ub)

#I want an approximation at (1.0,1.4)
approx = my_radial_basis((1.0,1.4))
```

## Kriging standard error
Let's now use the Kriging surrogate, which is a single-output Gaussian process.
This surrogate has a nice feature: not only does it approximate the solution at a
point, it also calculates the standard error at such point.
Let's see an example:
```@example kriging
using Surrogates
f = x -> exp(x)*x^2+x^3
lb = 0.0
ub = 10.0
x = sample(100,lb,ub,UniformSample())
y = f.(x)
p = 1.9
my_krig = Kriging(x,y,lb,ub,p=p)

#I want an approximation at 5.4
approx = my_krig(5.4)

#I want to find the standard error at 5.4
std_err = std_error_at_point(my_krig,5.4)
```

Let's now optimize the Kriging surrogate using Lower confidence bound method, this is just a one-liner:
```@example kriging
surrogate_optimize(f,LCBS(),lb,ub,my_krig,UniformSample())
```
Surrogate optimization methods have two purposes: they both sample the space in unknown regions and look for the minima at the same time.

## Lobachesky integral
The Lobachesky surrogate has the nice feature of having a closed formula for its
integral, which is something that other surrogates are missing.
Let's compare it with QuadGK:
```@examples
using Surrogates
using QuadGK
obj = x -> 3*x + log(x)
a = 1.0
b = 4.0
x = sample(2000,a,b,SobolSample())
y = obj.(x)
alpha = 2.0
n = 6
my_loba = LobacheskySurrogate(x,y,a,b,alpha=alpha,n=n)

#1D integral
int_1D = lobachesky_integral(my_loba,a,b)
int = quadgk(obj,a,b)
int_val_true = int[1]-int[2]
@assert int_1D ≈ int_val_true
```


## Example of NeuralSurrogate
Basic example of fitting a neural network on a simple function of two variables.
```@example
using Surrogates
using Flux
using Statistics

f = x -> x[1]^2 + x[2]^2
bounds = Float32[-1.0, -1.0], Float32[1.0, 1.0]
# Flux models are in single precision by default.
# Thus, single precision will also be used here for our training samples.

x_train = sample(100, bounds..., SobolSample())
y_train = f.(x_train)

# Perceptron with one hidden layer of 20 neurons.
model = Chain(Dense(2, 20, relu), Dense(20, 1))
loss(x, y) = Flux.mse(model(x), y)

# Training of the neural network
learning_rate = 0.1
optimizer = Descent(learning_rate)  # Simple gradient descent. See Flux documentation for other options.
n_epochs = 50
sgt = NeuralSurrogate(x_train, y_train, bounds..., model=model, loss=loss, opt=optimizer, n_echos=n_epochs)

# Testing the new model
x_test = sample(30, bounds..., SobolSample())
test_error = mean(abs2, sgt(x)[1] - f(x) for x in x_test)
```
