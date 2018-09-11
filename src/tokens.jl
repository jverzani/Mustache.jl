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
        push!(tokens.tokens, token)
    end
end




mutable struct AnIndex
    ind::Int
    value::String
end
Base.string(ind::AnIndex) = string(ind.value)


### We copy some functions from Tokenize
function peekchar(io::Base.GenericIOBuffer)
    if !io.readable || io.ptr > io.size
        return EOF_CHAR
    end
    ch, _ = readutf(io)
    return ch
end

# this implementation is copied from Tokenize,
@inline function utf8_trailing(i)
    if i < 193
        return 0
    elseif i < 225
        return 1
    elseif i < 241
        return 2
    elseif i < 249
        return 3
    elseif i < 253
        return 4
    else
        return 5
    end
end

const utf8_offset = [0x00000000
                    0x00003080
                    0x000e2080
                    0x03c82080
                    0xfa082080
                    0x82082080]

function readutf(io, offset = 0)
    ch = convert(UInt8, io.data[io.ptr + offset])
    if ch < 0x80
        return convert(Char, ch), 0
    end
    trailing = utf8_trailing(ch + 1)
    c::UInt32 = 0
    for j = 1:trailing
        c += ch
        c <<= 6
        ch = convert(UInt8, io.data[io.ptr + j + offset])
    end
    c += ch
    c -= utf8_offset[trailing + 1]
    return convert(Char, c), trailing
end

####

## this is modified from dpeekchar in Tokenize
function peekaheadmatch(io::IOBuffer, m=['{','{'])
    if !io.readable || io.ptr > io.size
        return false
    end
    i,N = 1, length(m)
    ch1, trailing = readutf(io)
    ch1 != m[1] && return false
    offset = 0
    while true
        i == N && return true
        i += 1

        offset += trailing + 1
        if io.ptr + offset > io.size
            return false
        end
        chn, trailing = readutf(io, offset)
        chn != m[i] && return false
    end
    return false
end

# ...{{.... -> (..., {{....)
function scan_until!(io, tags, firstline)
    out = IOBuffer()
    while !end_of_road(io)
        if peekaheadmatch(io, tags)
            val = String(take!(out))
            close(out)
            return val, firstline
        else
            c = read(io, Char)
            firstline = firstline && !(c== '\n')
            print(out, c)
        end
    end
    val = String(take!(out))
    close(out)
    return val, firstline
end



# skip over tags
function scan_past!(io, tags = ('{','{'))
    for i in 1:length(tags)
        t = read(io, Char)
    end
end

# end of io stream
function end_of_road(io)
    !io.readable && return true
    io.ptr > io.size && return true
    return false
end



# stip whitespace at head of io stream
WHITESPACE = (' ', '\t')
function popfirst!_whitespace(io)

    while !end_of_road(io)
        c::Char = peekchar(io)
        !(c in WHITESPACE) && break
        read(io, Char)
    end
    
end

# is tag possibly standalone
# check the left side
function is_l_standalone(txt, firstline)
    if firstline
        occursin(r"^ *$", txt)
    else
        out = occursin(r"\n *$", txt)
        out
    end
end

# check the last side
function is_r_standalone(io)
    end_of_road(io) && return true
    offset = 0
    ch::Char, trailing::Int = readutf(io)
    while true
        ch == '\n' && return true
        !(ch in WHITESPACE) && return false
        offset += trailing + 1
        io.ptr + offset > io.size && return true
        ch, trailing = readutf(io, offset)
    end
    return false
end





## Make the intial set of tokens before nesting
## This will mutate tags
function make_tokens(template, tags)

    ltag, rtag = tags
    ltags = collect(ltag)
    rtags = collect(rtag)

    sections = MustacheTokens()
    tokens = MustacheTokens()
    
    firstline = true
    io = IOBuffer(template)
    while !end_of_road(io)
        # we have
        # ...text... {{ tag }} ...rest...
        # each lap makes token of ...text... and {{tag}} leaving ...rest...
        
        b0 = 0
        text_value, firstline = scan_until!(io, ltags, firstline)
        b1 = position(io)

        if end_of_road(io)
            token = Mustache.Token("text", text_value, b0, b1, (ltag, rtag))
            push!(tokens, token)
            return tokens
        end
        scan_past!(io, ltags)
        text_token = Mustache.Token("text", text_value, b0, b1, (ltag, rtag))

        # grab tag token
        t0 = position(io)
        token_value, firstline = scan_until!(io, rtags, firstline)
        t1 = position(io)

        if end_of_road(io)
            error("tag not closed: $token_value $ltag $rtag")
        end
        scan_past!(io, rtags)
        
        # what kinda tag did we get?
        _type = token_value[1:1]
        if _type in  ("#", "^", "/", ">", "<", "!", "|", "=", "{", "&")
            # type is first, we peel it off, also strip trailing = and },
            # as necessary

            token_value = stripWhitespace(token_value[2:(end-(_type == "="))])
            if _type == "{"
                # strip "}" if present in io
                c = peekchar(io)
                c == '}' && read(io, Char)
            end
            
            if _type == "="
                
                tag_token = Mustache.Token("=", token_value, t0, t1, (ltag, rtag))
                ts = String.(split(token_value, r"[ \t]+"))
                length(ts) != 2 && error("Change of delimiter must be a pair $ts")
                ltag, rtag = ts
                ltags, rtags = collect(ltag), collect(rtag)

            elseif _type == ">"

                # get indentation
                if firstline && occursin(r"^\h*$", text_value)
                    m = match(r"^(\h*)$", text_value)
                else
                    m = match(r"\n([\s\t\h]*)$", text_value)
                end
                indent = m == nothing ? "" : m.captures[1]
                tag_token = Token(_type, token_value, t0, t1, (ltag, rtag), indent)

            else

                tag_token = Mustache.Token(_type, token_value, t0, t1, (ltag, rtag))

            end
        else
            
            token_value = Mustache.stripWhitespace(token_value)
            tag_token = Mustache.Token("name", token_value, t0, t1, (ltag, rtag))

        end

        if tag_token._type == "name"
            firstline = false
        end

        # are we standalone?
        # yes if firstline and all whitespace
        # yes if !firstline and match \nwhitespace
        # AND
        # match rest with space[EOF,\n]

        standalone = is_r_standalone(io) && is_l_standalone(text_value, firstline)
        firstline = false
        
        if standalone && _type in ("!", "^", "/", "#", "<", ">", "|", "=")

            # we strip text_value back to \n or beginning
            text_token.value = replace(text_token.value, r" *$" => "")
            # strip whitspace at outset of io and "\n"
            popfirst!_whitespace(io)

            if !end_of_road(io)
                read(io, Char) # will be \n
                firstline = true
            end
            
        end
        
        push!(tokens, text_token)
        push!(tokens, tag_token)

        # account for matching/nested sections
        if _type == "#" || _type == "^" || _type ==  "|"
            push!(sections, tag_token)
        elseif _type == "/"
            ## section nestinng
            if length(sections) == 0
                error("Unopened section $token_value at $t0")
            end

            openSection = pop!(sections)
            if openSection.value != token_value
                error("Unclosed section: " * openSection.value * " at $t0")
            end
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
            if length(sections) > 0
                push!(sections[end].collector, token)
                collector = sections[end].collector
            else
                collector = tree
            end
        else
            push!(collector, token)
        end
    end

    return(tree)
end

## In lambdas with section this is used to go from the tokens to an unevaluated string
## This might have issues with space being trimmed
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
_toString(::Val{Symbol("^")}, token, ltag, rtag) = ltag * "^" * token.value * rtag
_toString(::Val{Symbol("|")}, token, ltag, rtag) = ltag * "|" * token.value * rtag
_toString(::Val{Symbol("/")}, token, ltag, rtag) = ltag * "/" * token.value * rtag 
_toString(::Val{Symbol(">")}, token, ltag, rtag) = ltag * ">" * token.value * rtag
_toString(::Val{Symbol("<")}, token, ltag, rtag) = ltag * "<" * token.value * rtag
_toString(::Val{Symbol("&")}, token, ltag, rtag) = ltag * "&" * token.value * rtag
_toString(::Val{Symbol("{")}, token, ltag, rtag) = ltag * "{" * token.value * rtag
_toString(::Val{Symbol("=")}, token, ltag, rtag) = ""
function _toString(::Val{Symbol("#")}, token, ltag, rtag)
    out = ltag * "#" * token.value * rtag 
    if !isempty(token.collector)
        out *= toString(token.collector)
    end
    out
end


          
          
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
                    print(buf, rowno > 0 ? indent : "", l)
                end
                renderTokens(io, parse(String(take!(buf))), writer, context, template)
                close(buf)
            else
                value = lookup(context, fname)
                if !falsy(value)

                    indent = token.indent
                    slashn = ""
                    # don't indent if last \n
                    if occursin(r"\n$", value)
                        value = chomp(value)
                        slashn = "\n"
                    end
                    buf = IOBuffer()
                    l = split(value, r"[\n]")
                    print(buf, indent*join(l, "\n"*indent))
                    tpl = String(take!(buf)) * slashn
                    renderTokens(io, parse(tpl), writer, context, template)
                    close(buf)
                end
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
