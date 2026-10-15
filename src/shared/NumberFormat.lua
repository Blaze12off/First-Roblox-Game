-- Display only: economy, validation and saved values always use the original numbers.
local N={}
local suffixes={"K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc"}
local function digits(value)
    return (string.format("%.2f",value):gsub("0+$",""):gsub("%.$",""))
end
function N.Compact(value)
    if type(value)~="number" or value~=value or math.abs(value)==math.huge then return "—" end
    local sign=value<0 and "-" or ""
    local n=math.abs(value)
    if n<1000 then
        local rounded=math.floor(n*100+.5)/100
        if rounded<1000 then return (rounded==0 and "" or sign)..digits(rounded) end
    end
    local tier,scaled=0,n
    while scaled>=1000 do scaled/=1000; tier+=1 end
    scaled=math.floor(scaled*100+.5)/100
    if scaled>=1000 then scaled/=1000; tier+=1 end
    if suffixes[tier] then return sign..digits(scaled)..suffixes[tier] end
    local exponent=math.floor(math.log10(n))
    local mantissa=n/10^exponent
    mantissa=math.floor(mantissa*100+.5)/100
    if mantissa>=10 then mantissa/=10; exponent+=1 end
    return sign..digits(mantissa).."E+"..exponent
end
return N
