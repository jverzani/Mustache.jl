type MustacheTokens
    tokens
end


## after parsing off to squash, nest and render the tokens

## take single character tokens and collaps into chunks
function squashTokens(tokens)
    squashedTokens = Array(Any, 0)
    
    lastToken = nothing
    for i in 1:length(tokens)
        token = tokens[i]
        if !falsy(lastToken) && token[1] == "text"  && lastToken[1] == "text"
            lastToken[2] *= token[2]
            lastToken[4] = token[4]
        else
            lastToken = token
            push!(squashedTokens, token)
        end
    end
    
    return(squashedTokens)
end



## Forms the given array of `tokens` into a nested tree structure where
## tokens that represent a section have two additional items: 1) an array of
## all tokens that appear in that section and 2) the index in the original
## template that represents the end of that section.
function nestTokens (tokens)
    tree = Array(Any,0)
    collector = tree
    sections = Array(Any, 0)
    
    for i in 1:length(tokens)
        token = tokens[i]
        ## a {{#name}}...{{/name}} will iterate over name
        ## a {{^name}}...{{/name}} does ... if we have no name
        ## start nesting
        if token[1] == "^" || token[1] == "#" 
            push!(sections, token)
            push!(collector, token)
            push!(token, Array(Any, 0))
            collector = token[5]
        elseif token[1] == "/"
            section = pop!(sections)
            push!(section, token[3])
            collector = length(sections) > 0 ? sections[length(sections)] : tree
        else
            push!(collector, token)
        end
    end

    function print_tree(x, k)
        for i in x
            if length(i) > 4
                println((k, i[1:4]))
                print_tree(i[5], k + 1)
            else
                println((k, i))
            end
        end
    end
    ## print_tree(tree, 1)

    return(tree) ## ?? Tree?
end


## Low-level function that renders the given `tokens` using the given `writer`
## and `context`. The `template` string is only needed for templates that use
## higher-order sections to extract the portion of the original template that
## was contained in that section.

function renderTokens(tokens, writer, context, template)
    
    buffer = ""
    
    for i in 1:length(tokens)
        token = tokens[i]
        tokenValue = token[2]

        if token[1] == "#"
            ## iterate over value
            value = lookup(context, tokenValue)

            ##  many things based on value of value
            if isa(value, Dict)
                for (k, v) in value
                    buffer *= renderTokens(token[5], writer, ctx_push(context, v), template)
                end
            elseif isa(value, Array)
                for v in value
                    buffer *= renderTokens(token[5], writer, ctx_push(context, v), template)
                end
            elseif isa(value, DataFrame)
                for i in 1:size(value)[1] ## iterate along row, Call one for each row
                    buffer *= renderTokens(token[5], writer, ctx_push(context, value[i,:]), template)
                end
            elseif !falsy(value)
                buffer *= renderTokens(token[5], writer, context, template)

            end

        elseif token[1] == "^"

            value = lookup(context, tokenValue)
            if !falsy(value)
                buffer *= renderTokens(token[5], writer, context, template)
            end


        elseif token[1] == ">"
            ## need partials to do this

        elseif token[1] == "&"
            value = lookup(context, tokenValue)
            if value != nothing
                buffer *= value
            end
    

        elseif token[1] == "name"
            value = lookup(context, tokenValue)
            if value != nothing
                buffer *= escape_html(value)
            end

        elseif token[1] == "text"
            buffer *= tokenValue

        end

    end

    return(buffer)
end
