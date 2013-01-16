## Main function to parse a template This works in several steps: each
## character parsed into a token, the tokens are squashed, then
## nested, then rendered.
function parse(template, tags)
    
    tags = ["{{", "}}"]         # we hard code tags!
    tagRes = ["\{\{", "\}\}"]   # escaped to be regular expressions

    scanner = Scanner(template)
    
    sections = Array(Any,0)
    tokens = Array(Any,0)
    spaces = Array(Integer,0)
    hasTag = false
    nonSpace = false
    
    function stripSpace(hasTag, nonSpace) 
        if hasTag && !nonSpace
            while length(spaces) > 0
                delete!(tokens, pop!(spaces))
            end
        else
            spaces = Array(Integer, 0)
        end
        
        hasTag = false
        nonSpace = false
    end
    
    while !eos(scanner)
        start = scanner.pos
        
        value = scanUntil!(scanner, tagRes[1])
        
        if !falsy(value) 
            for i in 1:length(value)
                chr = string(value[i])
                
                if isWhitespace(chr)
                    push!(spaces, length(tokens))
                else
                    nonSpace = true
                end
                
                push!(tokens, {"text", chr, start, start + 1})
                start += 1
                
                if chr == "\n"
                    stripSpace(hasTag, nonSpace)
                end
                
            end
        end
        
        if scan(scanner, tagRes[1]) == ""
            break
        end
        
        hasTag = true
        
        ## find type #,/,^,{, ...
        _type = scan(scanner, tagRe)
        
        if _type == ""
            _type = "name"
        end
        
        if _type == "="
            value = scanUntil!(scanner, eqRe)
            scan(scanner, eqRe)
            scanUntil!(scanner, tagRes[2])
        elseif _type == ""
            ## XXX hard code tags
            value = scanUntil!(scanner, r"\\s*\}\}\}") 
            scan(scanner, curlyRe)
            scanUntil!(scanner, tagRes[2])
            _type = "&"
        else
            value = scanUntil!(scanner, tagRes[2])
        end
        
        if scan(scanner, tagRes[2]) == ""
            error("Unclosed tag at " * string(scanner.pos))
        end
        
        
        token = {_type, value, start, scanner.pos}
        push!(tokens, token)
        
        if _type == "#" || _type == "^"
            push!(sections, token)
        elseif _type == "/"
            ## section nestinng
            if length(sections) == 0
                error("Unopened section $value at $start")
            end
            
            openSection = pop!(sections)
            if openSection[2] != value 
                error("Unclosed section" * openSection[2] * " at $start")
            end
            
        elseif _type == "name" || _type == "{" || _type == "&"
            nonSpace = true
        elseif _type == "="
            tags = split(value, spaceRe)
            if length(tags) != 2
                error("Invalid tags at $start:" * join(tags, ", "))
            end
            
        end
    end
        
    if length(sections) > 0
        openSection = pop!(sections)
        error("Unclosed section " * openSection[2] * "at " * scanner.pos)
    end
    
    tokens = squashTokens(tokens)
    out = nestTokens(tokens)
    
    out
end
