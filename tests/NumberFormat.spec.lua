local n=require("../src/shared/NumberFormat").Compact
local cases={{0,"0"},{12,"12"},{999,"999"},{1000,"1K"},{1250,"1.25K"},{10000,"10K"},
    {65264,"65.26K"},{100082,"100.08K"},{1e6,"1M"},{1e9,"1B"},{1e12,"1T"},
    {1e15,"1Qa"},{1e18,"1Qi"},{1e21,"1Sx"},{1e24,"1Sp"},{1e27,"1Oc"},
    {1e30,"1No"},{1e33,"1Dc"},{1e36,"1E+36"},{1.234e40,"1.23E+40"},
    {999999,"1M"},{999.999,"1K"},{-1250,"-1.25K"},{1e100,"1E+100"},
    {1e308,"1E+308"},{math.huge,"—"},{0/0,"—"},{-.0001,"0"}}
for _,case in cases do assert(n(case[1])==case[2],tostring(case[1])..": "..n(case[1]).." ~= "..case[2]) end
print("NUMBER_FORMAT_PASS "..#cases.." boundaries suffixes carry scientific finite_limits")
