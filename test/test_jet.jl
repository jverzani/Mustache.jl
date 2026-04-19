# needs newer Julia, so testing this requires bumping version
using Test
using Mustache
using JET

@testset "JET" begin
    JET.test_package(Mustache, ignored_modules=(AnyFrameModule(Base),))
end
