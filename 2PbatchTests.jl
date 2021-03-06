## Prepare Param and Metadata
includet("batch.jl")

param = Dict{Any,Any}(
    :dataexportroot => "O:\\AF4\\2P_analysis\\Summary\\DataExport",
    :interpolatedData => true,   # If you have multiplanes. True: use interpolated data; false: use uniterpolated data. Results are slightly different.
    :preOffset => 0.1,
    :responseOffset => 0.05,  # in sec
    :α => 0.05,   # p value
    :sampnum => 100,   # random sampling 100 times
    :fitThres => 0.5,
    :hueSpace => "DKL",   # Color space used? DKL or HSL
    :diraucThres => 0.8,   # if passed, calculate hue direction, otherwise calculate hue axis
    :oriaucThres => 0.5,
    :Respthres => 0.1,  # Set a response threshold to filter out low response cells?
    :blankId => 36,  # Blank Id
    :excId => [27,28,blankId])  # Exclude some condition?

meta = readmeta(joinpath(param[:dataexportroot],"metadata.mat"))
for t in 1:nrow(meta)
        meta.files[t]=meta.files[t][3:end]
end

## Query Tests
tests = @from i in meta begin
        # @where startswith(get(i.Subject_ID), "AF4")
        @where i.Subject_ID == "AF4"
        # @where i.RecordSite == "u002"
        @where i.ID == "DirSF"
        @where i.sourceformat == "Scanbox"
        @select {i.sourceformat,i.ID,i.files,i.UUID}
        @collect DataFrame
        end

## Condition Tests
batchtests(tests,param,plot=false)

## HartleySubspace Parametric and Image Response
param[:model]=[:STA]
param[:epprndelay]=1
param[:epprnft]=[3]
param[:epprlambda]=100

batchtests(tests,param,plot=false)
