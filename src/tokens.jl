
mutable struct Token
_type::String
value::String
start::Int
pos::Int
tags::Tuple{String, String}
indent::String
collector::Vector
Token(_type, value, start, pos, tags, indent="") = new(_type, value, start, pos, tags, indent, Any[])
end

mutable struct MustacheTokens
tokens::Vector{Token}
end
MustacheTokens() = MustacheTokens(Token[])


Base.length(tokens::MustacheTokens) = length(tokens.tokens)
Base.lastindex(tokens::MustacheTokens) = lastindex(tokens.tokens)
Base.getindex(tokens::MustacheTokens, ind) = getindex(tokens.tokens, ind)
Base.pop!(tokens::MustacheTokens) = pop!(tokens.tokens)

function Base.push!(tokens::MustacheTokens, token::Token)
    # squash if possible
    if length(tokens) == 0
        push!(tokens.tokens, token)
        return
    end
    
    lastToken = tokens[end]
    if !falsy(lastToken) && lastToken._type == "text" ==  token._type
        lastToken.value *= token.value
        lastToken.pos = token.pos
    else
        token._type == "text" && falsy(token.value) && return
        push!(tokens.tokens, token)
    end
end




mutable struct AnIndex
    ind::Int
    value::String
end
Base.string(ind::AnIndex) = string(ind.value)

## Make the intial set of tokens before nesting
function make_tokens(template, tags)
    
    rtags = [asRegex(tags[1]), asRegex(tags[2])]
    

    
    st_standalone = r"\n *$"
    end_standalone = r"^ +\n"
    # also have tagRe regular expression to process

    scanner = Scanner(template)

    sections = MustacheTokens()
    tokens = MustacheTokens()
    

    first_line = true
    while !eos(scanner)

        # in a loop we
        # * scanUntil to match opening tag
        # * scan to identify _type
        # * scanUntil to grab token value
        # * scan to end of closing tag
        # we end with text, type, value and associated positions
        text_start, text_end = scanner.pos, -1
        token_start = text_start
        text_value = token_value = ""

        ## XXX to incorporate different tokens, need to make regular expressions changeable
        ## eqRe, spaceRe, tagRe, ...

        # scan to match opening tag

        
        text_value = scanUntil!(scanner, rtags[1])
        token_start += lastindex(text_value)

        # No more? If so, save token and leave
        if scan!(scanner, rtags[1]) == ""
            text_token = Token("text", text_value, text_start, text_end, (tags[1],tags[2]))
            push!(tokens, text_token)
            break
        end

        ## find type #,/,^,{, ...
        _type = scan!(scanner, tagRe)

        if _type == ""
            _type = "name"
        end

        # grab value within tag
        if _type == "="
            token_value = stripWhitespace(scanUntil!(scanner, eqRe))
            scan!(scanner, eqRe)
            scanUntil!(scanner, rtags[2])
        elseif _type == "{" # Hard code tags
            token_value = scanUntil!(scanner, rtags[2])
            scan!(scanner, r"}")
        else
            token_value = scanUntil!(scanner, rtags[2])
        end

        # unclosed tag?
        if scan!(scanner, rtags[2]) == ""
            error("Unclosed tag at " * string(scanner.pos))
        end

        ## is the tag "standalone?
        ## standalone comments get special treatment
        ## here we identify if a tag is standalone
        ## This is *alot* of work for this task.
        ## XXX Speed this up
        ls, rs = false, false
        first_line = first_line &&  !occursin(r"\n", text_value)
        last_line = !occursin(r"\n", scanner.tail)
        
        if first_line
            ls = occursin(r"^ *$", text_value)
        else
            ls = occursin(r"\n *$", text_value)
        end
        
        if ls
            if last_line
                if occursin(r"^ *$", scanner.tail)
                    rs = true
                end
            else
                if occursin(r"^ *\n", scanner.tail)
                    rs = true
                end
            end
        end
        standalone = ls && rs

        
        # remove \n and space for standalone tags
        still_first_line = false
        if standalone && _type in ("!", "^", "/", "#", "<", ">", "|", "=")

            if !(_type in ("<",">"))
                 text_value = replace(text_value, r" *$" => "")
            end

            ## desc: "\r\n" should be considered a newline for standalone tags.
            if last_line
                scanner.tail = replace(scanner.tail, r"^ *"=>"")
            else
                scanner.tail = replace(scanner.tail, r"^ *\r{0,1}\n"=>"")
                still_first_line = true # clobbered \n, so keep as first line
            end
        end
        first_line = still_first_line


        # Now we can add tokens
        # add text_token, token_token
            text_token = Token("text", text_value, text_start, text_end, (tags[1],tags[2]))
        if _type != ">"
            token_token = Token(_type, token_value, token_start, scanner.pos, (tags[1],tags[2]))
        else
            indent = match(r"\h*$", text_value).match
            token_token = Token(_type, token_value, token_start, scanner.pos, (tags[1],tags[2]), indent)
        end
        push!(tokens, text_token)
        push!(tokens, token_token)


        # account for matching/nested sections
        if _type == "#" || _type == "^" || _type ==  "|"
            push!(sections, token_token)
        elseif _type == "/"
            ## section nestinng
            if length(sections) == 0
                error("Unopened section $token_value at $token_start")
            end

            openSection = pop!(sections)
            if openSection.value != token_value
                error("Unclosed section" * openSection.value * " at $token_start")
            end

        elseif _type == "name" || _type == "{" || _type == "&"
            nonSpace = true
        elseif _type == "="
            tags[1], tags[2] = String.(split(token_value, spaceRe))
            if length(tags) != 2
                error("Invalid tags at $token_start:" * join(tags, ", "))
            end
            rtags[1], rtags[2] = asRegex.(tags)
        end

    end

    if length(sections) > 0
        openSection = pop!(sections)
        error("Unclosed section " * string(openSection.value) * "at " * string(scanner.pos))
    end

    return(tokens)
end



## Forms the given array of `tokens` into a nested tree structure where
## tokens that represent a section have two additional items: 1) an array of
## all tokens that appear in that section and 2) the index in the original
## template that represents the end of that section.
function nestTokens(tokens)
    tree = Array{Any}(undef, 0)
    collector = tree
    sections = MustacheTokens() #Array{Any}(undef, 0)

    for i in 1:length(tokens)
        token = tokens[i]
        ## a {{#name}}...{{/name}} will iterate over name
        ## a {{^name}}...{{/name}} does ... if we have no name
        ## start nesting
        if token._type == "^" || token._type == "#" || token._type == "|"
            push!(sections, token)
            push!(collector, token)
            token.collector = Array{Any}(undef, 0)
            collector = token.collector
        elseif token._type == "/"
            section = pop!(sections)
            collector = length(sections) > 0 ? sections[end].collector : tree
        else
            push!(collector, token)
        end
    end

    return(tree)
end

## In lambdas with section this is used to go from the tokens to an unevaluated string
## XXX Token should have tags embedded in it
function toString(tokens)
    io = IOBuffer()
    for token in tokens
        write(io, _toString(Val{Symbol(token._type)}(), token, token.tags...))
    end
    out = String(take!(io))
    close(io)
    out
end

_toString(::Val{:name}, token, ltag, rtag) = ltag * token.value * rtag
_toString(::Val{:text}, token, ltag, rtag) = token.value
_toString(::Val{Symbol("#")}, token, ltag, rtag) = ltag * "#" * token_value * rtag
_toString(::Val{Symbol("^")}, token, ltag, rtag) = ltag * "^" * token_value * rtag
_toString(::Val{Symbol("|")}, token, ltag, rtag) = ltag * "|" * token_value * rtag
_toString(::Val{Symbol("/")}, token, ltag, rtag) = ltag * "/" * token_value * rtag
_toString(::Val{Symbol(">")}, token, ltag, rtag) = ltag * ">" * token_value * rtag
_toString(::Val{Symbol("<")}, token, ltag, rtag) = ltag * "<" * token_value * rtag
_toString(::Val{Symbol("&")}, token, ltag, rtag) = ltag * "&" * token_value * rtag
_toString(::Val{Symbol("{")}, token, ltag, rtag) = ltag * "{" * token_value * rtag
_toString(::Val{Symbol("=")}, token, ltag, rtag) = ""

          
          
# render tokens with values given in context
function renderTokensByValue(value, io, token, writer, context, template)

    if is_dataframe(value)
        for i in 1:size(value)[1]
            renderTokens(io, token.collector, writer, ctx_push(context, value[i,:]), template)
        end
    else
        inverted = token._type == "^"
        if (inverted && falsy(value)) || !falsy(value)
            _renderTokensByValue(value, io, token, writer, context, template)
        end
    end
end

## Helper function for dispatch based on value in renderTokens
function _renderTokensByValue(value::Dict, io, token, writer, context, template)
    renderTokens(io, token.collector, writer, ctx_push(context, value), template)
end


function _renderTokensByValue(value::Array, io, token, writer, context, template)
   inverted = token._type == "^"
   if (inverted && falsy(value))
       renderTokens(io, token.collector, writer, ctx_push(context, ""), template)
   else
        for v in value
            renderTokens(io, token.collector, writer, ctx_push(context, v), template)
        end
    end
end

## ## DataFrames
## function renderTokensByValue(value::DataFrames.DataFrame, io, token, writer, context, template)
##     ## iterate along row, Call one for each row
##     for i in 1:size(value)[1]
##         renderTokens(io, token.collector, writer, ctx_push(context, value[i,:]), template)
##     end
## end

## what to do with an index value `.[ind]`?
## We have `.[ind]` being of a leaf type (values are not pushed onto a Context) so of simple usage
function _renderTokensByValue(value::AnIndex, io, token, writer, context, template)
    
    if token._type == "#" || token._type == "|"
        # print if match
        if value.value == context.view
            renderTokens(io, token.collector, writer, context, template)
        end
    elseif token._type == "^"
        # print if *not* a match
        if value.value != context.view
            renderTokens(io, token.collector, writer, context, template)
        end
    else
        renderTokens(io, token.collector, writer, ctx_push(context, value.value), template)
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

    #    out = (value())(token.collector, render)
    if token._type == "name"
        out = render(value(), context.view)
    elseif token._type == "|"
        # pass evaluated values
        view = context.parent.view
        sec_value = render(MustacheTokens(token.collector), view)
        out = render(value(sec_value), view)
    else
        ## How to get raw section value?
        ## desc: Lambdas used for sections should receive the raw section string.
        ## Lambdas used for sections should parse with the current delimiters.
        sec_value = toString(token.collector)
        view = context.parent.view        
        tpl = value(sec_value)

        out = render(parse(tpl, token.tags),  view)

    end
    write(io, out)

end

function _renderTokensByValue(value::Any, io, token, writer, context, template)
    inverted = token._type == "^"
    if (inverted && falsy(value)) || !falsy(value)
        renderTokens(io, token.collector, writer, context, template)
    end
end



## Low-level function that renders the given `tokens` using the given `writer`
## and `context`. The `template` string is only needed for templates that use
## higher-order sections to extract the portion of the original template that
## was contained in that section.
function renderTokens(io, tokens, writer, context, template)
    for i in 1:length(tokens)
        token = tokens[i]
        tokenValue = token.value


        if token._type == "#" || token._type == "|"
            ## iterate over value if Dict, Array or DataFrame,
            ## or display conditionally
            value = lookup(context, tokenValue)

            if !isa(value, AnIndex)
                context = Context(value, context)
            end
            renderTokensByValue(value, io, token, writer, context, template)

        elseif token._type == "^"
            
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

        elseif token._type == ">"
            ## partials: desc: Each line of the partial should be indented before rendering.
            fname = stripWhitespace(tokenValue)
            if isfile(fname)
                indent = token.indent
                buf = IOBuffer()
                for (rowno, l) in enumerate(eachline(fname, keep=true))
                    # we don't strip indent from first line, so we don't indent that
                    print(buf, rowno > 1 ? indent : "", l)
                end
                renderTokens(io, parse(String(take!(buf))), writer, context, template)
                close(buf)
            end

        elseif token._type == "<"
            ## partials without parse
            fname = stripWhitespace(tokenValue)
            if isfile(fname)
                print(io, open(x -> read(x, String), fname))
            else
                @warn("File $fname not found")
            end

        elseif token._type == "&"
            value = lookup(context, tokenValue)
            if !falsy(value)
                ## desc: A lambda's return value should parse with the default delimiters.
                ##       parse(value()) ensures that
                val = isa(value, Function) ? render(parse(value()), context.view) : value
                print(io, val)
            end

        elseif token._type == "{"
            value = lookup(context, tokenValue)
            if !falsy(value)
                val = isa(value, Function) ? render(parse(value()), context.view) : value
                print(io, val)
            end

        elseif token._type == "name"
            value = lookup(context, tokenValue)
            if !falsy(value)
                val = isa(value, Function) ? render(parse(value()), context.view) : value
                print(io, escape_html(val))
            end

        elseif token._type == "text"
            print(io, string(tokenValue))
        end

    end

end
