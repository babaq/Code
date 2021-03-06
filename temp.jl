using NeuroAnalysis,Makie,Colors,Plots,GeometryTypes

x = 1:10
y=1:10
u=fill(0.5,10)
v = fill(0.5,10)
arrows(x,y,u,v)





OriMarker = Shape([(0.5,0.2),(-0.5,0.2),(-0.5,-0.2),(0.5,-0.2)])



a=[0.5 -0.5 -0.5 0.5;
    0.2 0.2 -0.2 -0.2]
Shape(a)





unitposition.+[-1 0]

LineSegment((-1,1))

oris=rand(0:360,20)
unitposition = [ rand(20:70,20) rand(20:70,20)]
unitgood=rand(Bool,20)


Vec2f0[(0.5,0.2),(-0.5,0.2),(-0.5,-0.2),(0.5,-0.2)]



m = Point2f0[(0,0), (0, 1), (0.5, 0.5), (1, 1), (1, 0)]
meshscatter(rand(1:7,20),rand(0:3,20), marker=GLPlainMesh(m),rotations=rand(0:2π,20))



AbstractPlotting.set_theme!(
    plot = (show_axis = false, scale_plot = false),
    color = :turquoise1
)
poly(HyperRectangle(Vec2f0(0), Vec2f0(1,100)))



t = load("C:\\Users\\fff00\\Command\\Recordings\\0040.png")

tt=t[200:600,200:600]

gt=Gray.(tt)

ggt=gray.(gt)

plot(ggt[:,200])

using Makie,Plots,CairoMakie,GLMakie

AbstractPlotting.inline!(false)

p=Makie.scatter(1:2,1:2,marker=rand(RGB{Float32},10,10),markersize=(50,10))

Makie.scatter(1:2,1:2,marker=[rand(RGB{Float32},10,10), rand(RGB{Float32},20,10)],markersize=[(50,10),(10,50)])



imgs = [rand(RGB{Float32},20,10), rand(RGB{Float32},10,20)]
Makie.scatter(1:2,1:2,marker=imgs,markersize=size.(imgs))

CairoMakie.activate!()
GLMakie.activate!()

dataset = prepare("Y:\\AF5\\AF5_HLV1_ODL1_HartleySubspace_1.mat")
dataset = prepare("Y:\\AF5\\AF5_HLV1_ODL3_Flash2Color_2.mat")




using Interact,Plots,VegaLite,DataFrames,Distances,LinearAlgebra
@vlplot(:point,rand(10),rand(10))

Dict(Pair.(1:3,2:4))

using Interact,Plots
@manipulate for i in 1:10
    heatmap(rand(10,10),color=:temperaturemap)
end



Makie.surface(x,y,z,colormap=:coolwarm,shading=false)

sufstr=["_A","_L","_M","_S"];tcdir="E:\\Code\\temp"
for u in sort(collect(keys(dataset["ulsta"])))
    for t in [1,2,3,4]
    tdir = "Z:\\AF5\\AF5_HLV1_ODL1\\AF5_HLV1_ODL1_OriSF_$t"
    nm = "Single-Unit_$(u)_SpatialFreqTuning"
    fs = matchfile(Regex("$nm.png"),dir=tdir,adddir=true)
    if !isempty(fs)
   cp(fs[1],joinpath(tcdir,"$nm$(sufstr[t]).png"),force=true)
end
end
end

ct = Dict()
for u in sort(collect(keys(dataset["ulsta"])))
    # push!(ct,u=>"DO")
    ct[u]="DO"
end

ct

YAML.write_file("temp/cell type1.yaml",ct)

using YAML

us = collect(keys(ct))
up = up[si,:]
us = us[si]

si = sortperm(up[:,1])
jit = [cumsum(range(0.0000001,length=58,step=0.0000002)) .+ rand(0:0.00002:1,58) ones(58)]

plotunitposition(up.*jit,unitid=us,layer=layer,unitgood=trues(58),markersize=0,unitidsize=7)


savefig("unitposition.svg")



ct = YAML.load_file("cell type.yaml")
for u in keys(ct)
    tdir = "Z:\\AF5\\AF5_HLV1_ODL3\\AF5_HLV1_ODL3_Color_1"
    nm = "Single-Unit_$(u)_HueAngleTuning"
    fs = matchfile(Regex("$nm.png"),dir=tdir,adddir=true)
    if !isempty(fs)
       cp(fs[1],joinpath(tcdir,"$nm.png"),force=true)
    end
end









using NeuroAnalysis,Test,Plots,Interact,Statistics, BenchmarkTools,StatsPlots,DataFrames

t = prepare("Y:\\AF5\\AF5_HLV1_ODL3_Color_1.mat")


twf = t["spike_kilosort"]["templateswaveformfeature"]
twff = t["spike_kilosort"]["clusterwaveformfeature"]

twff = t["spike"]["unitfeature"]

sui = t["spike"]["unitgood"]

fns = collect(keys(twff))

@manipulate for x in fns, y in fns
    scatter(twff[x][sui],twff[y][sui],markersize=3,leg=false)
end

tt=t["lf"]["meta"]
tt["from"]

tt["roapgain"]
tt["savedchans"]
tt["snsSaveChanSubset"]

@manipulate for i = 1:size(twf, 1)
    ps, freq = powerspectrum(twf[i:i, :], 30000, freqrange = [3000, 12000])
    p = plot(layout=(4,1),size=(800,200*4))
    w = twf[i, :]
    plot!(subplot=1,w)
    plot!(subplot=2,freq, ps[1,:],ylims=[0,1e-5])
    fw = hlpass(twf[i:i,:],30000,high=150,low=12000)[1,:]
    plot!(subplot=3,fw)
    plot!(subplot=4,w.-fw,ylims=[-1e0,1e0])
end


rt = matread("ttt.mat")

save("ttt.jld2",t)


load("ttt.jld2","cg")

a=[1,2,3]

a[begin:begin]
a=rand(3,4)


a[begin:begin,:]

b = a[:,argmax(a,dims=2)]

[i[1]*i[2] for i in CartesianIndices(a)]




imagepatch(img,10,(0.5,0.5))
## Tuning Properties in layers
layer = load(joinpath(siteresultdir,"layer.jld2"),"layer")
# testids = ["$(siteid)_$(lpad(i,3,'0'))" for i in [8,12,13,14]]

testids = ["$(siteid)_OriSF_$i" for i in 1:5]
testn=length(testids)
ds = load.(joinpath.(siteresultdir,testids,"factorresponse.jld2"))
testtitles = ["$(i["color"])" for i in ds]
spikes = load.(joinpath.(siteresultdir,testids,"spike.jld2"),"spike")

f = :Ori
p=plot(layout=(1,testn),link=:all,legend=false,grid=false,xlims=(10,60))
for i in 1:testn
    vi = spikes[i]["unitgood"].&ds[i]["responsive"].&ds[i]["modulative"]
    if f in [:Ori,:Ori_Final]
        color = map((i,j)->j ? HSV(i.oo,1-i.ocv/1.5,1) : RGBA(0.5,0.5,0.5,0.1),ds[i]["factorstats"][:Ori_Final],vi)
    elseif f==:Dir
        color = map((i,j)->j ? HSV(i.od,1-i.dcv/1.5,1) : RGBA(0.5,0.5,0.5,0.1),ds[i]["factorstats"][:Ori_Final],vi)
    end
    scatter!(p,subplot=i,spikes[i]["unitposition"][:,1],spikes[i]["unitposition"][:,2],color=color,markerstrokewidth=0,markersize=2,title=testtitles[i],titlefontsize=8)
    if !isnothing(layer)
        hline!(p,subplot=i,[layer[k][1] for k in keys(layer)],linestyle=:dash,annotations=[(17,layer[k][1],text(k,5,:gray20,:bottom)) for k in keys(layer)],linecolor=:gray30,legend=false)
    end
end
p
foreach(i->savefig(joinpath(siteresultdir,"Layer_UnitPosition_$(f)_Tuning$i")),[".png",".svg"])



if plot
    vi = uresponsive.&umodulative.&unitgood.&uenoughresponse
    pfactor=intersect([:Ori,:Ori_Final],keys(ufs))
    if length(pfactor)>0
        pfactor=pfactor[1]
        colorspace = ex["Param"]["ColorSpace"]
        hues = ex["Param"]["Color"]
        title = "UnitPosition_$(colorspace)_$(hues)_OptOriDirSF"
        p=plotunitpositionproperty(unitposition[vi,:],title=title,ori=map(i->i.oo,ufs[pfactor][vi]),os=map(i->1-i.ocv,ufs[pfactor][vi]),
        dir = map(i->i.od,ufs[pfactor][vi]),ds=map(i->1-i.dcv,ufs[pfactor][vi]),sf=map(i->i.osf,ufs[:SpatialFreq][vi]),layer=layer)
        foreach(i->save(joinpath(resultdir,"$title$i"),p),[".png",".svg"])

        oos = map(i->i.oo,ufs[pfactor][vi])
        oos = [oos;oos.+180]
        ys,ns,ws,is = histrv(oos,0,360,nbins=20)
        oa = deg2rad.(mean.([ws;ws[1]]))
        oh = [ns;ns[1]]./2

        ys,ns,ws,is = histrv(map(i->i.od,ufs[pfactor][vi]),0,360,nbins=20)
        da = deg2rad.(mean.([ws;ws[1]]))
        dh = [ns;ns[1]]

        title = "$(colorspace)_$(hues)_OptOriDirHist"
        Plots.plot([oa da],[oh dh],title=title,projection=:polar,linewidth=2,label=["Ori" "Dir"])
        foreach(i->savefig(joinpath(resultdir,"$title$i")),[".png",".svg"])
    end
    if haskey(ufs,:ColorID)
        plotunitposition(unitposition,color=map((i,j)->j ? HSV(i.oh,1-i.hcv,1) : HSVA(0,0,0.5,0.2),ufs[:ColorID],umodulative))
        foreach(i->savefig(joinpath(resultdir,"UnitPosition_Hue_Tuning$i")),[".png",".svg"])
    end
end


## Test
ys = reshape2mask(epochsamplenp(mmlf,fs,[condon[1] condon[end]+1000],1:nch,meta=lfmeta,bandpass=[]),exchmask)

dy = 1e6*ys[:,1,:]
dy=csd(1e6*ys[:,1,:],h=hy)


ps,freq=powerspectrum(1e6dy,fs,freqrange=[0,10])

t=periodogram(dy[100,:];fs)
t=welch_pgram(dy[100,:];fs)
t=mt_pgram(dy[100,:];fs,nw=10)

plot(t.freq,t.power)

plotanalog(log10.(amp),x=freq1,y=depths,xlabel="Freqency",xunit="Hz",timeline=[],clims=:auto,color=:vik)
plotanalog(pha,x=freq1,y=depths,xlabel="Freqency",xunit="Hz",timeline=[],clims=:auto,color=:vik)


t=rfft(dy,2)
freq = rfftfreq(size(dy,2),fs)


t1=t[:,freq.<2]
freq1=freq[freq.<2]
amp=abs.(t1)
pha = angle.(t1)

f1i=argmin(abs.(freq.-0.33))
f2i=argmin(abs.(freq.-0.66))
f3i=argmin(abs.(freq.-0.99))

plot(depths,log10.(amp[:,f1i]))
plot(depths,log10.(amp[:,f2i]))
plot(depths,log10.(amp[:,f3i]))

plot(depths,pha[:,f1i])
plot(depths,pha[:,f2i])
plot(depths,pha[:,f3i])
