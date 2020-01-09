using NeuroAnalysis,Statistics,FileIO,Plots,Interact,Dierckx,PyCall

# Combine all layer tests of one recording site
dataroot = "../Data"
dataexportroot = "../DataExport"
resultroot = "../Result"

subject = "AF5";recordsession = "HLV1";recordsite = "ODL3"
siteid = join(filter(!isempty,[subject,recordsession,recordsite]),"_")
resultsitedir = joinpath(resultroot,subject,siteid)
layer = Dict("WM"=>[0,0],"Out"=>[3500,3500])

# testids = ["$(siteid)_00$i" for i in 0:3]
# testn=length(testids)
# testtitles = ["Eyeₚ","Eyeₙₚ","Eyes","EyeₚS"]
# csds = load.(joinpath.(sitedir,testids,"csd.jld2"),"csd","depth","fs")
# depths=csds[1][2];fs=csds[1][3]

testids = ["$(siteid)_Flash2Color_$i" for i in 1:4]
testn=length(testids)
## Plot all CSD
csds = load.(joinpath.(resultsitedir,testids,"csd.jld2"))
testtitles = ["$(i["log"])_$(i["color"])" for i in csds]
fs=csds[1]["fs"]

csdb = [0 15]
csdr = [25 100]
csdbi = epoch2samplerange(csdb,fs)
csdri = epoch2samplerange(csdr,fs)
csdx = csdri./fs .* 1000
csdss = map(i->imfilter(stfilter(i["csd"],temporaltype=:sub,ti=csdbi),Kernel.gaussian((0.9,1)))[:,csdri],csds)
clim=maximum(abs.(vcat(csdss...)))

p=plot(layout=(1,testn),link=:all,legend=false)
for i in 1:testn
    heatmap!(p,subplot=i,csdx,csds[1]["depth"],csdss[i],color=:RdBu,clims=(-clim,clim),title=testtitles[i],titlefontsize=8)
    if !isnothing(layer)
        hline!(p,subplot=i,[layer[k][1] for k in keys(layer)],linestyle=:dash,annotations=[(csdx[1]+7,layer[k][1],text(k,5,:gray20,:bottom)) for k in keys(layer)],linecolor=:gray30,legend=false)
    end
end
p
foreach(i->savefig(joinpath(resultsitedir,"Layer_CSD$i")),[".png",".svg"])


## Plot all Power Spectrum
pss = load.(joinpath.(sitedir,testids,"powerspectrum.jld2"),"rcps","depth","freq")
depths=pss[1][2];freq=pss[1][3]

pss = map(i->i[1],pss)
clim=maximum(vcat(pss...))

p=plot(layout=(1,testn),link=:all,legend=false)
for i in 1:testn
    heatmap!(p,subplot=i,freq,depths,pss[i],color=:fire,clims=(0,clim),title=testtitles[i])
    if !isnothing(layer)
        hline!(p,subplot=i,[layer[k][1] for k in keys(layer)],linestyle=:dash,annotations=[(freq[1]+5,layer[k][1],text(k,6,:gray20,:bottom)) for k in keys(layer)],linecolor=:gray30,legend=false)
    end
end
foreach(i->savefig(joinpath(sitedir,"layer_power_rc$i")),[".png",".svg"])


## Plot all Depth PSTH
depthpsths = load.(joinpath.(resultsitedir,testids,"depthpsth.jld2"))
x=depthpsths[1]["x"];bw = x[2]-x[1]

psthb = [0 15]
psthr = [25 100]
psthbi = epoch2samplerange(psthb,1/(bw*SecondPerUnit))
psthri = epoch2samplerange(psthr,1/(bw*SecondPerUnit))
psthx = psthri .* bw
psthss = map(i->imfilter(stfilter(i["depthpsth"],temporaltype=:sub,ti=psthbi),Kernel.gaussian((0.9,1)))[:,psthri],depthpsths)
clims=extrema(vcat(psthss...))

p=plot(layout=(1,testn),link=:all,legend=false)
for i in 1:testn
    heatmap!(p,subplot=i,psthx,depthpsths[1]["depth"],psthss[i],color=:Reds,clims=clims,title=testtitles[i],titlefontsize=8)
    n = depthpsths[i]["n"]
    pn = maximum(psthx) .- n./maximum(n) .* maximum(psthx) .* 0.2
    plot!(p,subplot=testn,pn,depthpsths[1]["depth"],label="Number of Units",color=:seagreen,lw=0.5)
    if !isnothing(layer)
        hline!(p,subplot=i,[layer[k][1] for k in keys(layer)],linestyle=:dash,annotations=[(psthx[1]+7,layer[k][1],text(k,5,:gray20,:bottom)) for k in keys(layer)],linecolor=:gray30,legend=false)
    end
end
p
foreach(i->savefig(joinpath(resultsitedir,"Layer_DepthPSTH$i")),[".png",".svg"])


## Plot all unit position
spikes = load.(joinpath.(resultsitedir,testids,"spike.jld2"),"spike")

p=plot(layout=(1,testn),link=:all,legend=false,grid=false,xlims=(10,60))
for i in 1:testn
    scatter!(p,subplot=i,spikes[i]["unitposition"][:,1],spikes[i]["unitposition"][:,2],color=map(i->i ? :darkgreen : :gray30,spikes[i]["unitgood"]),
    alpha=0.5,markerstrokewidth=0,markersize=3,series_annotations=text.(spikes[i]["unitid"],2,:gray10,:center),title=testtitles[i],titlefontsize=8)
    if !isnothing(layer)
        hline!(p,subplot=i,[layer[k][1] for k in keys(layer)],linestyle=:dash,annotations=[(17,layer[k][1],text(k,5,:gray20,:bottom)) for k in keys(layer)],linecolor=:gray30,legend=false)
    end
end
foreach(i->savefig(joinpath(resultsitedir,"Layer_UnitPosition$i")),[".png",".svg"])











# earliest response should be due to LGN M,P input to 4Ca,4Cb
ln = ["4Cb","4Ca","4B","4A","2/3","Out"]
lcsd = dropdims(mean(mncsd[:,epoch2samplerange([0.045 0.055],fs)],dims=2),dims=2)
ldepths = depths[1]:depths[end]
lcsd = Spline1D(depths,lcsd)(ldepths);threshold = 1.2std(lcsd)

scipysignal = pyimport("scipy.signal")
di,dv=scipysignal.find_peaks(-lcsd,prominence=threshold,height=threshold)
peaks =ldepths[di.+1];bases = hcat(ldepths[dv["left_bases"].+1],ldepths[dv["right_bases"].+1])

plot(lcsd,ldepths,label="CSD Profile")
vline!([-threshold,threshold],label="Threshold")
hline!(peaks,label="CSD Sink Peak")
hline!(bases[:,1],label="CSD Sink Low Border")
hline!(bases[:,2],label="CSD Sink High Border")

layer = Dict(ln[i]=>bases[i,:] for i in 1:size(bases,1))
plotanalog(mncsd,fs=fs,color=:RdBu,layer=layer)


# Layers from Depth PSTH
depthpsth,depths,x = load(joinpath(resultdir,"depthpsth.jld2"),"depthpsth","depth","x")
plotpsth(depthpsth,x,depths,layer=layer)

bw = x[2]-x[1]
lpsth = dropdims(mean(depthpsth[:,epoch2samplerange([0.045 0.055],1/bw)],dims=2),dims=2)
ldepths = depths[1]:depths[end]
lpsth = Spline1D(depths,lpsth)(ldepths);threshold = 1.2std(lpsth)

scipysignal = pyimport("scipy.signal")
di,dv=scipysignal.find_peaks(lpsth,prominence=threshold,height=threshold)
peaks =ldepths[di.+1];bases = hcat(ldepths[dv["left_bases"].+1],ldepths[dv["right_bases"].+1])

plot(lpsth,ldepths,label="PSTH Profile")
vline!([-threshold,threshold],label="Threshold")
hline!(peaks,label="PSTH Peak")
hline!(bases[:,1],label="PSTH Low Border")
hline!(bases[:,2],label="PSTH High Border")












layer["Out"]=[2800,3900]
layer["1"]=[2160,1800]
layer["2/3"]=[2250,1800]
layer["2"]=[2550,1800]
layer["3"]=[2550,1800]
layer["4A/B"]=[2100,1800]
layer["4A"]=[2550,1800]
layer["4B"]=[2000,1800]
layer["4C"]=[1800,1800]
layer["4Ca"]=[1850,1800]
layer["4Cb"]=[1580,1300]
layer["5/6"]=[1130,1800]
layer["5"]=[1300,1800]
layer["6"]=[1500,1800]
layer["WM"]=[0,0]
# Finalize Layers
save(joinpath(resultsitedir,"layer.jld2"),"layer",checklayer(layer))



## Tuning Properties in layers
layer = load(joinpath(resultsitedir,"layer.jld2"),"layer")
# testids = ["$(siteid)_$(lpad(i,3,'0'))" for i in [8,12,13,14]]

testids = ["$(siteid)_OriSF_$i" for i in 1:5]
testn=length(testids)
ds = load.(joinpath.(resultsitedir,testids,"factorresponse.jld2"))
testtitles = ["$(i["color"])" for i in ds]
spikes = load.(joinpath.(resultsitedir,testids,"spike.jld2"),"spike")

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
foreach(i->savefig(joinpath(resultsitedir,"Layer_UnitPosition_$(f)_Tuning$i")),[".png",".svg"])