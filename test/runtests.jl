using Test
using NastranResults

import NastranResults.readmeta!,
       NastranResults.readcomponents!,
       NastranResults.PCHLL,
       NastranResults.collect,
       NastranResults.PunchModalData,
       NastranResults.PMData,
       NastranResults.PunchFrequencyData,
       NastranResults.PFData


# need to implement this soon
function unit_test_readop4_nofile()
    @test true
end


"""
    test readop4 constants
"""
function unit_test_op4_constants()
    @test NastranResults.COL == 65536
    @test NastranResults.iCOL == 1/NastranResults.COL
    @test NastranResults.MAT_ALL == "ALL"
    @test NastranResults.MAT_NAMES == "NAMES"
end


function unit_test_readop4_names()
    @test true
end


function unit_test_readop4_nomatrix()
    @test true
end


function unit_test_readop4_MAA()
    @test true
end


function unit_test_readop4_KAA()
    @test true
end


function unit_test_readop4_ALL()
    @test true
end


function unit_test_readop4_correct()
    @test true
end


function unit_test_readpch_nofile()
    @test true
end


"""
    test readpunch constants
"""
function unit_test_readpch_constants()
    @test NastranResults.TITLE == "TITLE"
    @test NastranResults.SUBTITLE == "SUBTITLE"
    @test NastranResults.LABEL == "LABEL"
    @test NastranResults.SUBCASE_ID == "SUBCASE ID"
    @test NastranResults.EIGENVALUE == "EIGENVALUE"
    @test NastranResults.MODE == "MODE"
    @test NastranResults.POINT == "POINT ID"
    @test NastranResults.INCLUDE == "INCLUDE"
    @test NastranResults.SINGLEP == 7
    @test NastranResults.DOUBLEP == 15
    @test NastranResults.PCHL == 18
    @test NastranResults.PCHLL == 73
    @test NastranResults.DOLLAR == '\$'
    @test NastranResults.CONT == "-CONT-"
    @test NastranResults.EQUAL == '='
end


"""
    test function readmeta! for modal type
"""
function unit_test_readpch_readmeta_modal()
    lines = []
    push!(lines, "\$TITLE   = EIGENMODES                                                          1")
    push!(lines, "\$SUBTITLE= SUBTITLE                                                            2")
    push!(lines, "\$LABEL   =EIGENMODES ANALYSIS                                                  3")
    push!(lines, "\$EIGENVECTOR                                                                   4")
    push!(lines, "\$REAL OUTPUT                                                                   5")
    push!(lines, "\$SUBCASE ID =           1                                                      6")
    push!(lines, "\$EIGENVALUE =  1.0000000E+00  MODE =     1                                     7")

    data = PunchModalData()
    for line in lines
        line = line[1:PCHLL]
        readmeta!(data, line)
    end

    @test data.title == "EIGENMODES"
    @test data.subtitle == "SUBTITLE"
    @test data.label == "EIGENMODES ANALYSIS"
    @test data.datatype == "EIGENVECTOR"
    @test data.outputtype == "REAL OUTPUT"
    @test data.subcaseid == 1
    @test data.eigenvalue == 1.0
    @test data.mode == 1
end


"""
    test function reameta! for frequency type
"""
function unit_test_readpch_readmeta_frequency()
    lines = []
    push!(lines, "\$TITLE   = TITLE                                                               1")
    push!(lines, "\$SUBTITLE= 1 X                                                                 2")
    push!(lines, "\$LABEL   = 1 X                                                                 3")
    push!(lines, "\$DISPLACEMENTS                                                                 4")
    push!(lines, "\$REAL-IMAGINARY OUTPUT                                                         5")
    push!(lines, "\$SUBCASE ID =           2                                                      6")
    push!(lines, "\$POINT ID =           1  IDENTIFIED BY FREQUENCY                               7")
    
    data = PunchFrequencyData()
    for line in lines
        line = line[1:PCHLL]
        readmeta!(data, line)
    end
    
    @test data.title == "TITLE"
    @test data.subtitle == "1 X"
    @test data.label == "1 X"
    @test data.datatype == "DISPLACEMENTS"
    @test data.outputtype == "REAL-IMAGINARY OUTPUT"
    @test data.subcaseid == 2
    @test data.point == 1
end


"""
    test function readcomponents! for modal type
"""
function unit_test_readpch_readcomponents_modal()
    l1 = "  00000001       G      1.000000E+00      2.000000E+00      3.000000E+00       1"
    l2 = "-CONT-                 -4.000000E+00      5.000000E+00      6.000000E+00       2"

    data = PunchModalData()
    node = Vector{Int}(undef, 0)
    readcomponents!(data, node, l1)
    readcomponents!(data, node, l2)

    @test node[1] == 1
    @test data.eigenvector[1] ==  1.0
    @test data.eigenvector[2] ==  2.0
    @test data.eigenvector[3] ==  3.0
    @test data.eigenvector[4] == -4.0
    @test data.eigenvector[5] ==  5.0
    @test data.eigenvector[6] ==  6.0
end


"""
    test function readcomponents! for frequency type
"""
function unit_test_readpch_readcomponents_frequency()
    l1 = "    0.000000E+00 G     -1.000000E+00      2.000000E+00      3.000000E+00       1"
    l2 = "-CONT-                 -4.000000E+00      5.000000E+00      6.000000E+00       2"
    l3 = "-CONT-                 -7.000000E+00      8.000000E+00      9.000000E+00       3"
    l4 = "-CONT-                 -1.000000E+01      1.100000E+01      1.200000E+01       4"
    lines = [l1, l2, l3, l4]
    
    data = PunchFrequencyData()
    frequency = Vector{Float64}(undef, 0)
    next = iterate(lines)
    (line, state) = next
    readcomponents!(data, frequency, line, lines, state)
    
    @test frequency[1] == 0.0
    @test data.response[1] == -1 - 7im
    @test data.response[2] ==  2 + 8im
    @test data.response[3] ==  3 + 9im
    @test data.response[4] == -4 - 10im
    @test data.response[5] ==  5 + 11im
    @test data.response[6] ==  6 + 12im
end


"""
    test function readpch! for frequency type
"""
function integration_test_readpch_modal()
    data = readpch("$(@__DIR__)/assets/modal.pch", PunchModalData)

    @test data.node == [1]
    @test data.modal[1].title == "EIGENMODES"
    @test data.modal[1].subtitle == "SUBTITLE"
    @test data.modal[1].label == "EIGENMODES ANALYSIS"
    @test data.modal[1].datatype == "EIGENVECTOR"
    @test data.modal[1].outputtype == "REAL OUTPUT"
    @test data.modal[1].subcaseid == 1
    @test data.modal[1].eigenvalue == 1.0
    @test data.modal[1].mode ==  1
    @test data.modal[1].eigenvector ==  [1, 2, 3, -4, 5, 6]
end


"""
    test function readpch! for frequency type
"""
function integration_test_readpch_frequency()
    data = readpch("$(@__DIR__)/assets/frequency.pch", PunchFrequencyData)

    @test data.frequency == [0.0]
    @test data.response[1].title == "TITLE"
    @test data.response[1].subtitle == "1 X"
    @test data.response[1].label == "1 X"
    @test data.response[1].datatype == "DISPLACEMENTS"
    @test data.response[1].outputtype == "REAL-IMAGINARY OUTPUT"
    @test data.response[1].subcaseid == 2
    @test data.response[1].point ==  1
    @test data.response[1].response ==  [-1-7im, 2+8im, 3+9im, -4-10im, 5+11im, 6+12im]
end


"""
    test function collect for modal type
"""
function unit_test_collect_modal()
    data = Vector{PunchModalData}(undef, 0)
    node = Vector{Int}(undef, 0)
    n = 3
    testvector = randn(5, n) 
    for i = 1:n
        mdata = PunchModalData()
        mdata.eigenvector = testvector[:, i]
        push!(node, i)
        push!(data, mdata)
    end
    testdata = PMData(data, node)
    d = collect(testdata)

    for i in 1:n
        @test d[:, i] == testvector[:, i]
    end
end


"""
    test function collect for frequency type
"""
function unit_test_collect_frequency()
    data = Vector{PunchFrequencyData}(undef, 0)
    node = Vector{Int}(undef, 0)
    n = 3
    testvector = randn(5, n) + randn(5, n)*im
    for i = 1:n
        mdata = PunchFrequencyData()
        mdata.response = testvector[:, i]
        push!(node, i)
        push!(data, mdata)
    end
    testdata = PFData(data, node)
    d = collect(testdata)

    for i in 1:n
        @test d[:, i] == testvector[:, i]
    end
end


# these tests look more like integration tests but ok for now 
@testset "Test OP4  " begin
    unit_test_readop4_nofile()
    unit_test_op4_constants()

    # need small test file
    #unit_test_readop4_nonames()
    #unit_test_readop4_nomatrix()
    #unit_test_readop4_MAA()
    #unit_test_readop4_KAA()
    #unit_test_readop4_ALL()
    #unit_test_readop4_correct()
end


@testset "Test PUNCH" begin
    unit_test_readpch_nofile()
    unit_test_readpch_constants()
    unit_test_readpch_readmeta_modal()
    unit_test_readpch_readmeta_frequency()
    unit_test_readpch_readcomponents_modal()
    unit_test_readpch_readcomponents_frequency()

    unit_test_collect_modal()
    unit_test_collect_frequency()

    integration_test_readpch_modal()
    integration_test_readpch_frequency()
end


#@testset "Test HDF5 " begin
#    @test true
#end