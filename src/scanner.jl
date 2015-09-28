## Scanner

type Scanner
    string::AbstractString
    tail::AbstractString
    pos::Integer
end
Scanner(string::AbstractString) = Scanner("", string, 0)



## Returns `true` if the tail is empty (end of string).
function eos(s::Scanner)
    s.tail == ""
end


## Tries to match the given regular expression at the current position.
## Returns the matched text if it can match, the empty string otherwise.
function scan(s::Scanner, re::Regex)
    if !ismatch(re, s.tail)
        return ""
    end

    m = match(re, s.tail)
    if m.offset >= 1
        ## move past match
        no_chars = endof(m.match) + m.offset - 1
        s.pos += no_chars
        s.tail = s.tail[(no_chars + 1):end]
    end

    m.match
end
scan(s::Scanner, re::AbstractString) = scan(s, Regex(re))
scan(s::Scanner, re::Char) = scan(s, string(re))

## Skips all text until the given regular expression can be matched. Returns
## the skipped string, which is the entire tail if no match can be made.
function scanUntil!(s::Scanner, re::Regex)
    m = match(re, s.tail)

    if m == nothing
        ourmatch = s.tail
        s.pos += endof(s.tail)
        s.tail = ""
    else
        pos = m.offset
        ourmatch = s.tail[1:(pos-1)]
        s.tail = s.tail[pos:(endof(s.tail))]
        s.pos += pos
    end

    return(ourmatch)
end

scanUntil!(s::Scanner, re::AbstractString) = scanUntil!(s, Regex(re))
scanUntil!(s::Scanner, re::Char) = scanUntil!(s, string(re))



