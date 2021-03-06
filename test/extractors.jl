using JsonGrinder, JSON, Test, SparseArrays, Flux
using JsonGrinder: ExtractScalar, ExtractCategorical, ExtractArray, ExtractBranch
using Mill: catobs
using LinearAlgebra

@testset "Testing scalar conversion" begin
	sc = ExtractScalar(Float64,2,3)
	@test all(sc("5").data .== [9])
	@test all(sc(5).data .== [9])
	@test all(sc(nothing).data .== [0])
end

@testset "Testing array conversion" begin
	sc = ExtractArray(ExtractCategorical(2:4))
	@test all(sc([2,3,4]).data.data .== Matrix(1.0I, 4, 3))
	@test ismissing(sc(nothing).data)
	@test all(sc(nothing).bags.bags .== [0:-1])
	sc = ExtractArray(ExtractScalar(Float64))
	@test all(sc([2,3,4]).data.data .== [2 3 4])
	@test ismissing(sc(nothing).data)
	@test all(sc(nothing).bags.bags .== [0:-1])
end


@testset "Testing ExtractBranch" begin
	vector = Dict("a" => ExtractScalar(Float64,2,3),"b" => ExtractScalar(Float64));
	other = Dict("c" => ExtractArray(ExtractScalar(Float64,2,3)));
	br = ExtractBranch(vector,other)
	a1 = br(Dict("a" => 5, "b" => 7, "c" => [1,2,3,4]))
	a2 = br(Dict("a" => 5, "b" => 7))
	a3 = br(Dict("a" => 5, "c" => [1,2,3,4]))
	@test all(catobs(a1,a1).data[1].data .==[7 7; 9 9])
	@test all(catobs(a1,a1).data[2].data.data .== [-3 0 3 6 -3 0 3 6])
	@test all(catobs(a1,a1).data[2].bags .== [1:4,5:8])

	@test all(catobs(a1,a2).data[1].data .==[7 7; 9 9])
	@test all(catobs(a1,a2).data[2].data.data .== [-3 0 3 6])
	@test all(catobs(a1,a2).data[2].bags .== [1:4,0:-1])

	@test all(catobs(a2,a3).data[1].data .==[7 0; 9 9])
	@test all(catobs(a2,a3).data[2].data.data .== [-3 0 3 6])
	@test all(catobs(a2,a3).data[2].bags .== [0:-1,1:4])

	@test all(catobs(a1,a3).data[1].data .==[7 0; 9 9])
	@test all(catobs(a1,a3).data[2].data.data .== [-3 0 3 6 -3 0 3 6])
	@test all(catobs(a1,a3).data[2].bags .== [1:4,5:8])


	br = ExtractBranch(vector,nothing)
	a1 = br(Dict("a" => 5, "b" => 7, "c" => [1,2,3,4]))
	a2 = br(Dict("a" => 5, "b" => 7))
	a3 = br(Dict("a" => 5, "c" => [1,2,3,4]))
	@test all(a1.data .==[7; 9])
	@test all(a2.data .==[7; 9])
	@test all(a3.data .==[0; 9])


	br = ExtractBranch(nothing,other)
	a1 = br(Dict("a" => 5, "b" => 7, "c" => [1,2,3,4]))
	a2 = br(Dict("a" => 5, "b" => 7))
	a3 = br(Dict("a" => 5, "c" => [1,2,3,4]))

	@test all(a1.data.data .== [-3 0 3 6])
	@test all(a1.bags .== [1:4])
	@test all(catobs(a1,a1).data.data .== [-3 0 3 6 -3 0 3 6])
	@test all(catobs(a1,a1).bags .== [1:4,5:8])

	@test all(catobs(a1,a2).data.data .== [-3 0 3 6])
	@test all(catobs(a1,a2).bags .== [1:4,0:-1])


	@test all(a3.data.data .== [-3 0 3 6])
	@test all(a3.bags .== [1:4])
	@test all(catobs(a3,a3).data.data .== [-3 0 3 6 -3 0 3 6])
	@test all(catobs(a3,a3).bags .== [1:4,5:8])
end


@testset "Testing Nested Missing Arrays" begin
	other = Dict("a" => ExtractArray(ExtractScalar(Float64,2,3)),"b" => ExtractArray(ExtractScalar(Float64,2,3)));
	br = ExtractBranch(nothing,other)
	a1 = br(Dict("a" => [1,2,3], "b" => [1,2,3,4]))
	a2 = br(Dict("b" => [2,3,4]))
	a3 = br(Dict("a" => [2,3,4]))
	a4 = br(Dict{String,Any}())

	@test all(catobs(a1,a2).data[1].data.data .== [-3.0  0.0  3.0  6.0  0.0  3.0  6.0])
	@test all(catobs(a1,a2).data[1].bags .== [1:4, 5:7])
	@test all(catobs(a1,a2).data[2].data.data .== [-3.0  0.0  3.0])
	@test all(catobs(a1,a2).data[2].bags .== [1:3, 0:-1])


	@test all(catobs(a2,a3).data[1].data.data .== [0.0  3.0  6.0])
	@test all(catobs(a2,a3).data[1].bags .== [1:3, 0:-1])
	@test all(catobs(a2,a3).data[2].data.data .== [0 3 6])
	@test all(catobs(a2,a3).data[2].bags .== [0:-1, 1:3])


	@test all(catobs(a1,a4).data[1].data.data .== [-3.0  0.0  3.0  6.0])
	@test all(catobs(a1,a4).data[1].bags .== [1:4, 0:-1])
	@test all(catobs(a1,a4).data[2].data.data .== [-3.0  0.0  3.0])
	@test all(catobs(a1,a4).data[2].bags .== [1:3, 0:-1])
end

@testset "ExtractOneHot" begin
	samples = ["{\"name\": \"a\", \"count\" : 1}",
		"{\"name\": \"b\", \"count\" : 2}",]
	vs = JSON.parse.(samples)

	e = ExtractOneHot(["a","b"], "name", "count")
	@test e(vs).data[:] ≈ [1, 2, 0]
	@test e(nothing).data[:] ≈ [0, 0, 0]
	@test typeof(e(vs).data) == SparseMatrixCSC{Float32,Int64}
	@test typeof(e(nothing).data) == SparseMatrixCSC{Float32,Int64}


	e = ExtractOneHot(["a","b"], "name", nothing)
	@test e(vs).data[:] ≈ [1, 1, 0]
	@test e(nothing).data[:] ≈ [0, 0, 0]
	@test typeof(e(vs).data) == SparseMatrixCSC{Float32,Int64}
	@test typeof(e(nothing).data) == SparseMatrixCSC{Float32,Int64}
	vs = JSON.parse.(["{\"name\": \"c\", \"count\" : 1}"])
	@test e(vs).data[:] ≈ [0, 0, 1]
	@test typeof(e(vs).data) == SparseMatrixCSC{Float32,Int64}
end

@testset "ExtractCategorical" begin
	e = ExtractCategorical(["a","b"])
	@test e("a").data[:] ≈ [1, 0, 0]
	@test e("b").data[:] ≈ [0, 1, 0]
	@test e("z").data[:] ≈ [0, 0, 1]
	@test e(nothing).data[:] ≈ [0, 0, 1]
	@test typeof(e("a").data) == Flux.OneHotMatrix{Array{Flux.OneHotVector,1}}
	@test typeof(e(nothing).data) == Flux.OneHotMatrix{Array{Flux.OneHotVector,1}}

	@test e(["a", "b"]).data ≈ [1 0; 0 1; 0 0]
	@test typeof(e(["a", "b"]).data) == Flux.OneHotMatrix{Array{Flux.OneHotVector,1}}
end

@testset "show" begin
	e = ExtractCategorical(["a","b"])
	buf = IOBuffer()
	Base.show(buf, e)
	str_repr = String(take!(buf))
	@test str_repr == """Categorical d = 3\n"""

	e = ExtractOneHot(["a","b"], "name", nothing)
	buf = IOBuffer()
	Base.show(buf, e)
	str_repr = String(take!(buf))
	@test str_repr == """OneHot d = 3\n"""

	other = Dict("a" => ExtractArray(ExtractScalar(Float64,2,3)),"b" => ExtractArray(ExtractScalar(Float64,2,3)));
	br = ExtractBranch(nothing,other)
	buf = IOBuffer()
	Base.show(buf, br)
	str_repr = String(take!(buf))
	@test str_repr ==
"""
: struct
  Empty vec
  Other:
  ├── a: Array of
  │    └── Float64
  └── b: Array of
      └── Float64
"""

	vector = Dict("a" => ExtractScalar(Float64,2,3),"b" => ExtractScalar(Float64))
	other = Dict("c" => ExtractArray(ExtractScalar(Float64,2,3)))
	br = ExtractBranch(vector,other)
	buf = IOBuffer()
	Base.show(buf, br)
	str_repr = String(take!(buf))
	@test str_repr ==
"""
: struct
  Vec:
  ├── a: Float64
  └── b: Float64
  Other:
  └── c: Array of
      └── Float64
"""

	other1 = Dict("a" => ExtractArray(ExtractScalar(Float64,2,3)),"b" => ExtractArray(ExtractScalar(Float64,2,3)))
	br1 = ExtractBranch(nothing,other1)
	other = Dict("a" => ExtractArray(br1), "b" => ExtractScalar(Float64,2,3))
	br = ExtractBranch(nothing,other)
	buf = IOBuffer()
	Base.show(buf, br)
	str_repr = String(take!(buf))
	@test str_repr ==
"""
: struct
  Empty vec
  Other:
  ├── a: Array of
  │    └── : struct
  │          Empty vec
  │          Other:
  │          ├── a: Array of
  │          │    └── Float64
  │          └── b: Array of
  │              └── Float64
  └── b: Float64
"""
end

@testset "equals and hash test" begin
	other1 = Dict(
		"a" => ExtractArray(ExtractScalar(Float64,2,3)),
		"b" => ExtractArray(ExtractScalar(Float64,2,3)),
		"c" => ExtractCategorical(["a","b"]),
	)
	br1 = ExtractBranch(nothing,other1)
	other11 = Dict(
		"a" => ExtractArray(br1),
		"b" => ExtractScalar(Float64,2,3),
	)
	br11 = ExtractBranch(nothing,other11)

	other2 = Dict(
		"a" => ExtractArray(ExtractScalar(Float64,2,3)),
		"b" => ExtractArray(ExtractScalar(Float64,2,3)),
		"c" => ExtractCategorical(["a","b"]),
	)
	br2 = ExtractBranch(nothing,other2)
	other22 = Dict("a" => ExtractArray(br2), "b" => ExtractScalar(Float64,2,3))
	br22 = ExtractBranch(nothing,other22)

	@test hash(br11) === hash(br22)
	@test hash(br11) !== hash(br1)
	@test hash(br11) !== hash(br2)
	@test hash(br1) === hash(br2)

	@test br11 == br22
	@test br11 != br1
	@test br11 != br2
	@test br1 == br2
end
