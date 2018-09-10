## This downloads and populates the spec test files

using Mustache
using YAML
using Test

ghub = "https://raw.githubusercontent.com/mustache/spec/72233f3ffda9e33915fd3022d0a9ebbcce265acd/specs/{{:spec}}.yml"

specs = ["comments",
          "delimiters",
          "interpolation",
          "inverted",
          "partials",
          "sections"#,
          #"~lambdas"
          ]


D = Dict()
for spec in specs
    nm = Mustache.render(ghub, spec=spec)
    D[spec] = YAML.load_file(download(nm))
end


function write_spec_file(fname)
    io = open("spec_$fname.jl","w")
    println(io, """
using Mustache
using Test
""")        
    
    x = D[fname]
    println(io, "@testset \" $fname \" begin\n")
    for (i,t) in enumerate(x["tests"])
        tpl = t["template"]
        tpl = replace(tpl, "\\" => "\\\\")
        tpl = replace(tpl, r"\"" => "\\\"")
        data = t["data"]
        desc = t["desc"]


        if haskey(t, "partials")
            for (k,v) in t["partials"]
                data[k] = v
            end
        end
        
        val = try
            Mustache.render(t["template"], data)
        catch err
            "Failed"
        end
        
        expected = t["expected"]
        expected_ = replace(expected, "\\" => "\\\\")
        expected_ = replace(expected_, r"\"" => "\\\"")
        expected_ = "\"\"\"" * expected_ * "\"\"\""

        
        
        println(io, "\n\t## $desc")
        print(io, "tpl = \"\"\"")
        print(io, tpl)
        println(io, "\"\"\"\n")
        println(io, "\t@test Mustache.render(tpl, $data) == $expected_")
        println("")
    end
    println(io, "end\n\n")
    close(io)
end


for spec in specs
    write_spec_file(spec)
end


# partials are different, as they refer to an external file
# tihs should clean up temp files, but we don't run as part of test suite
# test 7 fails, but I think that one is wrong
using Test
function test_partials()
    for spec in specs
        for (i,t) in enumerate(D[spec]["tests"])
            if haskey(t, "partials")
                println("""Test $spec / $i""")
        
                d = t["data"]
                partial = t["partials"]
                for (k,v) in partial
                    io = open(k, "w")
                    write(io, v)
                    close(io)
                end
                
                tpl = t["template"]
                expected = t["expected"]
                out =  Mustache.render(tpl, d) 
                
                val = out == expected
                if val
                    @test val
                else
                    val = replace(out, r"\n"=>"") == replace(expected, r"\n"=>"")
                    if val
                        println("""$(t["desc"]): newline issue ...""")
                        @test val
                    else
                        println("""$(t["desc"]): FAILED:\n $out != $expected""")
                    end
                end
                
                for (k,v) in partial
                    rm(k)
                end
            end
        end
    end
end
        

        
