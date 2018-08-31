mutable struct MustacheTokens
    tokens
end

mutable struct AnIndex
    ind
    value
end
Base.string(ind::AnIndex) = string(ind.value)

## after parsing off to squash, nest and render the tokens

## Make the intial set of tokens before squashing and nesting
function make_tokens(template, tags)


    tags = ["{{", "}}"]         # we hard code tags!
    tagRes = [r"{{", r"}}"]


    scanner = Scanner(template)

    sections = Array{Any}(undef,0)
    tokens = Array{Any}(undef, 0)
    spaces = Array{Integer}(undef, 0)
    hasTag = false
    nonSpace = false

    function stripSpace(hasTag, nonSpace)
        if hasTag && !nonSpace
            while length(spaces) > 0
                delete!(tokens, pop!(spaces))
            end
        else
            spaces = Array{Integer}(undef,0)
        end

        hasTag = false
        nonSpace = false
    end

    while !eos(scanner)
        start = scanner.pos

        value = scanUntil!(scanner, tagRes[1])

        if !falsy(value)
#            for i in 1:length(value)
#                chr = string(value[i])
            for val in value
                chr = string(val)
                if isWhitespace(chr)
                    push!(spaces, length(tokens))
                else
                    nonSpace = true
                end

                push!(tokens, Any["text", chr, start, start + lastindex(chr)])
                start += lastindex(chr)

                if chr == "\n"
                    #stripSpace(hasTag, nonSpace)
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
        elseif _type == "{"
            value = scanUntil!(scanner, tagRes[2])
            scan(scanner, r"}")
        else
            value = scanUntil!(scanner, tagRes[2])
        end

        if scan(scanner, tagRes[2]) == ""
            error("Unclosed tag at " * string(scanner.pos))
        end

        token = Any[_type, value, start, scanner.pos]

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
        error("Unclosed section " * string(openSection[2]) * "at " * string(scanner.pos))
    end

    return(tokens)
end

## take single character tokens and collaps into chunks
function squashTokens(tokens)
    squashedTokens = Array{Any}(undef, 0)
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
function nestTokens(tokens)
    tree = Array{Any}(undef, 0)
    collector = tree
    sections = Array{Any}(undef, 0)

    for i in 1:length(tokens)
        token = tokens[i]
        ## a {{#name}}...{{/name}} will iterate over name
        ## a {{^name}}...{{/name}} does ... if we have no name
        ## start nesting
        if token[1] == "^" || token[1] == "#"
            push!(sections, token)
            push!(collector, token)
            push!(token, Array{Any}(undef, 0))
            collector = token[5]
        elseif token[1] == "/"
            section = pop!(sections)
            collector = length(sections) > 0 ? sections[end][5] : tree
        else
            push!(collector, token)
        end
    end

    function print_tree(x, k)
        for i in x
            if length(i) > 4
                println(" " ^ (k-1), (k, i[1:4]))
                print_tree(i[5], k+1)
            else
                println(" " ^ (k-1), (k, i))
            end
        end
    end

    return(tree)
end

function renderTokensByValue(value, io, token, writer, context, template)
    if is_dataframe(value)
        for i in 1:size(value)[1]
            renderTokens(io, token[5], writer, ctx_push(context, value[i,:]), template)
        end
    else
        inverted = token[1] == "^"
        if (inverted && falsy(value)) || !falsy(value)
            _renderTokensByValue(value, io, token, writer, context, template)
        end
    end
end

## Helper function for dispatch based on value in renderTokens
function _renderTokensByValue(value::Dict, io, token, writer, context, template)
    renderTokens(io, token[5], writer, ctx_push(context, value), template)
end


function _renderTokensByValue(value::Array, io, token, writer, context, template)
   inverted = token[1] == "^"
   if (inverted && falsy(value))
       renderTokens(io, token[5], writer, ctx_push(context, ""), template)
   else
        for v in value
            renderTokens(io, token[5], writer, ctx_push(context, v), template)
        end
    end
end

## ## DataFrames
## function renderTokensByValue(value::DataFrames.DataFrame, io, token, writer, context, template)
##     ## iterate along row, Call one for each row
##     for i in 1:size(value)[1]
##         renderTokens(io, token[5], writer, ctx_push(context, value[i,:]), template)
##     end
## end

## what to do with an index value `.[ind]`?
## We have `.[ind]` being of a leaf type (values are not pushed onto a Context) so of simple usage
function _renderTokensByValue(value::AnIndex, io, token, writer, context, template)
    if token[1] == "#"
        # print if match
        if value.value == context.view
            renderTokens(io, token[5], writer, context, template)
        end
    elseif token[1] == "^"
        # print if *not* a match
        if value.value != context.view
            renderTokens(io, token[5], writer, context, template)
        end
    else
        renderTokens(io, token[5], writer, ctx_push(context, value.value), template)
    end
end


function _renderTokensByValue(value::Function, io, token, writer, context, template)
    ## function get's passed
    # When the value is a callable
    # object, such as a function or lambda, the object will
    # be invoked and passed the block of text. The text
    # passed is the literal block, unrendered. {{tags}} will
    # not have been expanded - the lambda should do that on
    # its own. In this way you can implement filters or
    # caching.

    render = (tokens) -> begin
        sprint(io -> renderTokens(io, tokens, writer, context, template))
    end

    out = (value())(token[5], render)
    write(io, out)
end

function _renderTokensByValue(value::Any, io, token, writer, context, template)
    inverted = token[1] == "^"
    if (inverted && falsy(value)) || !falsy(value)
        renderTokens(io, token[5], writer, context, template)
    end
end



## Low-level function that renders the given `tokens` using the given `writer`
## and `context`. The `template` string is only needed for templates that use
## higher-order sections to extract the portion of the original template that
## was contained in that section.
function renderTokens(io, tokens, writer, context, template)
    for i in 1:length(tokens)
        token = tokens[i]
        tokenValue = token[2]

        if token[1] == "#"
            ## iterate over value if Dict, Array or DataFrame,
            ## or display conditionally
            value = lookup(context, tokenValue)
            if !isa(value, AnIndex)
                context = Context(value, context)
            end
            renderTokensByValue(value, io, token, writer, context, template)
            ## ##  many things based on value of value
            ## if isa(value, Dict)
            ##     renderTokens(io, token[5], writer, ctx_push(context, value), template)
            ## elseif isa(value, Array)
            ##     for v in value
            ##         renderTokens(io, token[5], writer, ctx_push(context, v), template)
            ##     end
            ## elseif Main.isdefined(:DataFrame) && isa(value, Main.DataFrame)
            ##     ## iterate along row, Call one for each row
            ##     for i in 1:size(value)[1]
            ##         renderTokens(io, token[5], writer, ctx_push(context, value[i,:]), template)
            ##     end
            ## elseif isa(value, Function)
            ##     ## function get's passed
            ##     # When the value is a callable
            ##     # object, such as a function or lambda, the object will
            ##     # be invoked and passed the block of text. The text
            ##     # passed is the literal block, unrendered. {{tags}} will
            ##     # not have been expanded - the lambda should do that on
            ##     # its own. In this way you can implement filters or
            ##     # caching.

            ##     function render(tokens)
            ##         sprint(io -> renderTokens(io, tokens, writer, context, template))
            ##     end

            ##     out = (value())(token[5], render)
            ##     write(io, out)

            ## elseif !falsy(value)
            ##     renderTokens(io, token[5], writer, context, template)
            ## end

        elseif token[1] == "^"
            
            ## display if falsy, unlike #
            value = lookup(context, tokenValue)
            if !isa(value, AnIndex)
                context = Context(value, context)

                if falsy(value)
                    renderTokensByValue(value, io, token, writer, context, template)
                end
            else
                # for indices falsy test is performed in
                # _renderTokensByValue(value::AnIndex,...)
                renderTokensByValue(value, io, token, writer, context, template)
            end

        elseif token[1] == ">"
            ## partials
            fname = stripWhitepace(tokenValue)
            if isfile(fname)
                renderTokens(io, template_from_file(fname).tokens, writer, context, template)
            end

        elseif token[1] == "<"
            ## partials without parse
            fname = stripWhitepace(tokenValue)
            if isfile(fname)
                print(io, open(x -> read(x, String), fname))
            else
                warn("File $fname not found")
            end

        elseif token[1] == "&"
            value = lookup(context, tokenValue)
            if value != nothing
                print(io, value)
            end

        elseif token[1] == "{"
            value = lookup(context, tokenValue)
            if value != nothing
                print(io, value)
            end

        elseif token[1] == "name"
            value = lookup(context, tokenValue)
            # we had Nullable field support here, but this is dropped
            # in v"0.7.0" in favor of Union{T, Nothing} so we check for nothing
            # we could add a check for Missing too
            value != nothing && print(io, escape_html(value))

        elseif token[1] == "text"
            print(io, string(tokenValue))
        end

    end

    #    return(buffer)
end
