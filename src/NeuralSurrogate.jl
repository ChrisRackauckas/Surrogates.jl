using Flux

mutable struct NeuralSurrogate{X,Y,M,L,O,P,N,A,U} <: AbstractSurrogate
    x::X
    y::Y
    model::M
    loss::L
    opt::O
    ps::P
    n_echos::N
    lb::A
    ub::U
 end


 """
 NeuralSurrogate(x,y,lb,ub,model,loss,opt,n_echos)

 - model: Flux layers
 - loss: loss function
 - opt: optimization function
 """
 function NeuralSurrogate(x,y,lb,ub,model,loss,opt,n_echos)
     X = vec.(collect.(x))
     data = zip(X, y)
     ps = Flux.params(model)
     @epochs n_echos Flux.train!(loss, ps, data, opt)
     return NeuralSurrogate(x,y,model,loss,opt,ps,n_echos,lb,ub)

 end

 function (my_neural::NeuralSurrogate)(val)
     v = [val...]
     if length(my_neural.y[1]) == 1
         out = my_neural.model(v)[1]
     else
         out = my_neural.model(v)
     end
     remove_tracker(out)
 end

function add_point!(my_n::NeuralSurrogate, x_new, y_new)
    if eltype(x_new) == eltype(my_n.x)
        append!(my_n.x, x_new)
        append!(my_n.y, y_new)
    else
        push!(my_n.x, x_new)
        push!(my_n.y, y_new)
    end
    X = vec.(collect.(my_n.x))
    data = zip(X, my_n.y)
    @epochs my_n.n_echos Flux.train!(my_n.loss, my_n.ps, data, my_n.opt)
    nothing
end
