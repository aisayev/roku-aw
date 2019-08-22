' Roku Another World (or, Out of This World) Experiment Channel - http://github.com/aisayev/roku-aw
' Brightscript remake developed by Artyom Isayev (Artem Isaiev)

function getByte()
    c = m.file024[m.pc]
    m.pc++
    return c
end function

function getWord()
   c = m.file024[m.pc] << 8
   m.pc++
   c = c or m.file024[m.pc]
   m.pc++
   return c
end function

function getShort()
   w = toShort(getWord())
   return w 
end function

function toShort(c)
    if c > &h07fff then c = c - &h10000
    return c
end function

function toUnsigned(i)
    if i >= 0 then
       c = i and &hffff 
    else
       c = (&h10000 + i) and &hffff
    end if
    return c
end function

sub skipBytes(c)
    m.pc += c
end sub
