## Main function to parse a template This works in several steps: each
## character parsed into a token, the tokens are squashed, then
## nested, then rendered.
function parse(template, tags = ("{{", "}}"))
    tokens = make_tokens(template, tags)
    out = nestTokens(tokens)
    MustacheTokens(out)
end
