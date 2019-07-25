function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function split(s)
    local ss = {}
    s:gsub("[^,]+", function(c) ss[#ss+1] = trim(c) end)
    return ss
end

local args = {...}
local infilename = args[2]
local outfilename = args[3]

local infp = io.open(infilename, "r")
local hfp = io.open(outfilename, "w")

local midcodes = {}
for line in infp:lines() do
    local tokens = {}
    line = line:gsub(" *#.*$", "")
    if (line ~= "") then
        local _, _, name, args, emitter = line:find("^(%w+)(%b()) *= *(%b())$")
        if not name then
            _, _, name, args = line:find("^(%w+)(%b())$")
        end
        if not name then
            error("syntax error in: "..line)
        end

        args = args or ""
        args = args:gsub("^%(", ""):gsub("%)$", "")

        midcodes[name] = { args = split(args or ""), emitter = emitter }
    end
end

hfp:write("#ifndef MIDCODES_IMPLEMENTATION\n")

hfp:write("enum {\n")
local first = true
for m, t in pairs(midcodes) do
    if not first then
        hfp:write(",")
    else
        first = false
    end
    hfp:write("MIDCODE_", m, "\n")
end
hfp:write("};\n");

hfp:write("union midcode_data {\n")
for m, md in pairs(midcodes) do
    if (#md.args > 0) then
        hfp:write("struct { ")
        for _, a in ipairs(md.args) do
            hfp:write(a, "; ")
        end
        hfp:write("} ", m:lower(), ";\n")
    end
end
hfp:write("};\n");

for m, md in pairs(midcodes) do
    hfp:write("extern void emit_mid_", m:lower(), "(")
    if (#md.args > 0) then
        local first = true
        for _, a in ipairs(md.args) do
            if first then
                first = false
            else
                hfp:write(",")
            end
            hfp:write(a)
        end
    else
        hfp:write("void")
    end
    hfp:write(");\n")
end

hfp:write("#else\n")

hfp:write("static struct midcode* add_midcode(void);\n")
hfp:write("static void push_midend_state_machine(void);\n")
for m, md in pairs(midcodes) do
    hfp:write("void emit_mid_", m:lower(), "(")
    if (#md.args > 0) then
        local first = true
        for _, a in ipairs(md.args) do
            if first then
                first = false
            else
                hfp:write(",")
            end
            hfp:write(a)
        end
    else
        hfp:write("void")
    end
    hfp:write(") {\n")
    hfp:write("\tstruct midcode* m = add_midcode();\n")
    hfp:write("\tm->code = MIDCODE_", m, ";\n")
    for _, a in ipairs(md.args) do
        local _, _, n = a:find("([^ ]+)$")
        hfp:write("\tm->u.", m:lower(), ".", n, " = ", n, ";\n")
    end
    hfp:write("\tpush_midend_state_machine();\n")
    hfp:write("}\n")
end

hfp:write("void print_midcode(struct midcode* m) {\n")
hfp:write("\tswitch (m->code) {\n")
for m, md in pairs(midcodes) do
    hfp:write("\t\tcase MIDCODE_", m, ":\n")
    hfp:write('\t\t\tprintf("', m, '(");\n')
    local e = md.emitter
    if e then
        e = e:gsub("%$%$", "m->u."..m:lower())
        hfp:write("\t\t\tprintf", e, ";\n")
    end
    hfp:write('\t\t\tprintf(")");\n')
    hfp:write("\t\t\tbreak;\n")
end
hfp:write("\t\tdefault:\n")
hfp:write('\t\t\tprintf("unknown(%d)", m->code);\n')
hfp:write("\t}\n")
hfp:write("}\n")

hfp:write("#endif\n")
hfp:close()
