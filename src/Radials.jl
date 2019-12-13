#=
Response surfaces implementantion, following:
"A Taxonomy of Global Optimization Methods Based on Response Surfaces"
by DONALD R. JONES
=#
mutable struct RadialBasis{F,X,Y,B,C} <: AbstractSurrogate
    phi::F
    dim_poly::Int
    x::X
    y::Y
    bounds::B
    coeff::C
end

"""
    RadialBasis(x,y,a::Number,b::Number,phi::Function,q::Int)

Constructor for RadialBasis surrogate
- (x,y): sampled points
- '(a,b)': interval of interest
-'phi': radial basis of choice
-'q': number of polynomial elements
"""
function RadialBasis(x, y, lb::Number, ub::Number, phi::Function, q::Int)
    coeff = _calc_coeffs(x, y, lb, ub, phi, q)
    return RadialBasis(phi, q, x, y, (lb, ub), coeff)
end

"""
RadialBasis(x,y,bounds,phi::Function,q::Int)

Constructor for RadialBasis surrogate

- (x,y): sampled points
- bounds: region of interest of the form [[a,b],[c,d],...,[w,z]]
- phi: radial basis of choice
- q: number of polynomial elements
"""
function RadialBasis(x, y, bounds, phi::Function, q::Int)
    coeff = _calc_coeffs(x, y, bounds[1], bounds[2], phi, q)
    return RadialBasis(phi, q, x, y, bounds, coeff)
end

function _calc_coeffs(x, y, lb, ub, phi, q)
    D = _construct_rbf_interp_matrix(x, first(x), lb, ub, phi, q)
    Y = _construct_rbf_y_matrix(y, first(y), length(y) + q)

    coeff = D \ Y
    return coeff
end

function _construct_rbf_interp_matrix(x, x_el::Number, lb, ub, phi, q)
    n = length(x)
    m = n + q
    D = zeros(eltype(x_el), m, m)

    @inbounds for i = 1:n
        for j = 1:n
            D[i,j] = phi(x[i] .- x[j])
        end
        if i <= n
            for k = 1:q
                D[i,n+k] = _scaled_chebyshev(x[i], k-1, lb, ub)
            end
        end
    end
    D_sym = Symmetric(D, :U)
    return D_sym
end

function _construct_rbf_interp_matrix(x, x_el, lb, ub, phi, q)
    n = length(x)
    nd = length(x_el)
    central_point = _center_bounds(x_el, lb, ub)
    sum_half_diameter = sum((ub[k]-lb[k])/2 for k = 1:nd)
    mean_half_diameter = sum_half_diameter / nd
    m = n+q
    D = zeros(eltype(x_el), m, m)

    @inbounds for i = 1:n
        for j = 1:n
            D[i,j] = phi(x[i] .- x[j])
        end
        if i < n + 1
            for k = 1:q
                D[i,n+k] = centralized_monomial(x[i], k-1, mean_half_diameter, central_point)
            end
        end
    end
    D_sym = Symmetric(D, :U)
    return D_sym
end

_construct_rbf_y_matrix(y, y_el::Number, m) = [i <= length(y) ? y[i] : zero(y_el) for i = 1:m]
_construct_rbf_y_matrix(y, y_el, m) = [i <= length(y) ? y[i][j] : zero(first(y_el)) for i=1:m, j=1:length(y_el)]

"""
    centralized_monomial(vect,alpha,mean_half_diameter,central_point)

Returns the value at point vect[] of the alpha degree monomial centralized.

#Arguments:
-'vect': vector of points i.e [x,y,...,w]
-'alpha': degree
-'mean_half_diameter': half diameter of the domain
-'central_point': central point in the domain
"""
function centralized_monomial(vect,alpha,mean_half_diameter,central_point)
    if iszero(alpha) return one(eltype(vect)) end
    centralized_product = prod(vect .- central_point)
    return (centralized_product / mean_half_diameter)^alpha
end

"""
Calculates current estimate of value 'val' with respect to RadialBasis object.
"""
function (rad::RadialBasis)(val)
    approx = _approx_rbf(val, rad)
    return _match_container(approx, first(rad.y))
end

function _approx_rbf(val::Number, rad)
    n = length(rad.x)
    q = rad.dim_poly
    approx = zero(rad.coeff[1, :])
    for i = 1:n
        approx += rad.coeff[i, :] * rad.phi(val .- rad.x[i])
    end
    for k = 1:q
        approx += rad.coeff[n+k, :] * _scaled_chebyshev(val, k-1, rad.bounds[1], rad.bounds[2])
    end
    return approx
end
function _approx_rbf(val, rad)
    n = length(rad.x)
    d = length(rad.x[1])
    q = rad.dim_poly
    lb, ub = rad.bounds
    sum_half_diameter = sum((ub[k]-lb[k])/2 for k = 1:d)
    mean_half_diameter = sum_half_diameter/d
    central_point = _center_bounds(first(rad.x), lb, ub)

    approx = zero(rad.coeff[1, :])
    @views approx += sum(rad.coeff[i, :] * rad.phi(val .- rad.x[i]) for i = 1:n)
    for k = 1:q
        @views approx += rad.coeff[n+k, :] .* centralized_monomial(val, k-1, mean_half_diameter, central_point)
    end
    return approx
end

_scaled_chebyshev(x, k, lb, ub) = cos(k*acos(-1 + 2*(x-lb)/(ub-lb)))
_center_bounds(x::Tuple, lb, ub) = ntuple(i -> (ub[i] - lb[i])/2, length(x))
_center_bounds(x, lb, ub) = (ub .- lb) ./ 2

"""
    add_point!(rad::RadialBasis,new_x,new_y)

Add new samples x and y and updates the coefficients. Return the new object radial.
"""
function add_point!(rad::RadialBasis,new_x,new_y)
    if (length(new_x) == 1 && length(new_x[1]) == 1) || ( length(new_x) > 1 && length(new_x[1]) == 1 && length(rad.bounds[1])>1)
        push!(rad.x,new_x)
        push!(rad.y,new_y)
    else
        append!(rad.x,new_x)
        append!(rad.y,new_y)
    end
    rad.coeff = _calc_coeffs(rad.x,rad.y,rad.bounds[1],rad.bounds[2],rad.phi,rad.dim_poly)
    nothing
end
