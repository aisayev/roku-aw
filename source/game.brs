' Roku Another World (or, Out of This World) Experiment Channel - http://github.com/aisayev/roku-aw
' Brightscript remake developed by Artyom Isayev (Artem Isaiev)

sub updateKeyboard()
    lr = 0
    mn = 0
    ud = 0

    if (m.keyMask and m.DIR_RIGHT) then
        lr = 1
        mn = mn or 1
    end if

    if (m.keyMask and m.DIR_LEFT) then
        lr = -1
        mn = mn or 2
    end if

    if (m.keyMask and m.DIR_DOWN) then
        ud = 1
        mn = mn or 4
    end if

    if (m.keyMask and m.DIR_UP) then
        ud = -1
        mn = mn or 8
    end if
    
    m.vars[&he3] = -1
    m.vars[&hfc] = lr
    m.vars[&hfd] = mn

    button = 0
    if (m.button) then
        button = 1
        mn = mn or &h80
    end if
       
    m.vars[&hfa] = button
    m.vars[&hfe] = mn
end sub

sub initScripts()

    for i = 0 to 63
        m.vectors[i] = &Hffff
        m.vectors2[i] = &Hffff
        m.paused[i] = 0
        m.paused2[i] = 0 
    end for

    m.vectors[0] = 0

    for i = 0 to 255
        m.vars[i] = 0
    end for

    m.vars[&H54] = &H81

end sub

sub rotateVectors()
    for i = 0 to 63
        m.paused[i] = m.paused2[i]
        if m.vectors2[i] <> &hffff then
            if m.vectors2[i] = &hfffe then
                m.vectors[i] = &hffff            
            else
                m.vectors[i] = m.vectors2[i] 
            end if
            m.vectors2[i] = &hffff
        end if
    end for
end sub


sub executeScript()
    m.halt = false
    while (not m.halt)
        op = getByte()

        if (op and &h80) then
            off = ((op << 8) or getByte()) * 2
            off = off and &hffff
            m.useAux = false
            x = getByte()
            y = getByte()
            h = y - 199
            if h > 0 then
                y = 199
                x += h
            end if
            drawShape(off, &hff, &h40, x, y)

        else if (op and &h40) then
            off = getWord() << 1
            off = off and &hffff
            m.useAux = false
            x = getByte()
            
            sw = op and &h30
            if sw = &h30 then 
                x+= &h100 
            else if sw = &h10 then 
                x = m.vars[x]
            else if sw = 0 then 
                x = toShort((x << 8) or getByte())
            endif 

            y = getByte()
            if ((op and &h8) = 0) then
                    if (op and &h04) = 0 then
                        y = toShort((y << 8) or getByte())
                    else
                        y = m.vars[y]
                    endif
            endif
            
            zoom = getByte()
            if ((op and &h2) = 0) then
                if ((op and 1) = 0) then
                    m.pc--
                    zoom = &h40
                else
                    zoom = m.vars[zoom]
                endif
            else
                if (op and 1) then
                   m.pc--
                   m.useAux = true
                   zoom = &h40
                endif
            endif
                            
            drawShape(off, &hff, zoom, x, y)
        else
        
            switch(op)
        
        endif   

    end while
end sub

sub switch(op)

    if (op = &h00) then
        i = getByte()
        m.vars[i] = getShort()
            
    else if (op = &h01) then
        i = getByte()
        j = getByte()
        m.vars[i] = m.vars[j]

    else if (op = &h02) then
        i = getByte()
        j = getByte()
        m.vars[i] += m.vars[j]

    else if (op = &h03) then
        i = getByte()
        v = getShort()
        m.vars[i] += v

    else if (op = &h04) then
        off = getWord()
        m.stack.push(m.pc)
        m.pc = off
    
    else if (op = &h05) then
        m.pc = m.stack.pop()
    
    else if (op = &h06) then
        m.halt = true

    else if (op = &h07) then
        m.pc = getWord()
    
    else if (op = &h08) then
         i = getByte()
         off = getWord()
         m.vectors2[i] = off

    else if (op = &h09) then
         i = getByte()
         m.vars[i]--
         off = getWord()
         if (m.vars[i] <> 0) then
            m.pc = off
         endif        

    else if (op = &h0a) then
         cmp = getByte()
         i = getByte()
         b = m.vars[i]
         if (cmp and &h80) then
            i = getByte()
            a = m.vars[i]
         else if (cmp and &h40) then
            a = getShort()
         else
            a = getByte()
         endif
         
         test = false
         sw = cmp and &h07
         if (sw = 0) then
             test = (a = b)
         else if (sw = 1)
             test = (a <> b)
         else if (sw = 2)
             test = (a < b)
         else if (sw = 3)
             test = (a <= b)
         else if (sw = 4)
             test = (a > b)
         else if (sw = 5)
             test = (a >= b)
         endif
                              
         off = getWord()
         if (test) then
             m.pc = off
         endif        
    
    else if (op = &h0b) then
         m.curPalette = getByte()
         skipBytes(1)    
    
    else if (op = &h0c) then
         j = getByte() and &h3f
         i = getByte() and &h3f
         n = i - j
         if (n >= 0) then
            n++
            al = getByte()
            if (al = 2) then
               for p = 0 to (n - 1)
                  m.vectors2[p+j] = &hfffe
               end for
            else if (al < 2) then
               for p = 0 to (n - 1)
                  m.paused2[p+j] = al
               end for
            endif
         endif    
    
    else if (op = &h0d) then
        page = getByte()
        m.currentPage1 = getScreenAddress(page)

    else if (op = &h0e) then
        s = getByte()
        c = getByte()
        fillScreen(s, c)

    else if (op = &h0f) then
        i = getByte()
        j = getByte()
        copyScreen(i, j)
    
    else if (op = &h10) then
        page = getByte()
        m.vars[&hf7] = 0
        if (page <> &hfe) then
            if (page = &hff) then
                t = m.currentPage2
                m.currentPage2 = m.currentPage3
                m.currentPage3 = t
            else
                m.currentPage2 = getScreenAddress(page)
            endif
        endif
        updateDisplay(m.currentPage2)
    
    else if (op = &h11) then
        m.halt = true
        m.pc = &hffff
    
    else if (op = &h12) then
        i = getWord()
        x = getByte()
        y = getByte()
        c = getByte()
        drawString(i, x*8, y, c)
   
    else if (op = &h13) then
        i = getByte()
        j = getByte()
        m.vars[i] -= m.vars[j]
        
    else if (op = &h14) then
        i = getByte()
        v = getWord()
        m.vars[i] = toShort(toUnsigned(m.vars[i]) and v)
        
    else if (op = &h15) then
        i = getByte()
        v = getWord()
        m.vars[i] = toShort(toUnsigned(m.vars[i]) or v)

    else if (op = &h16) then
        i = getByte()
        v = getShort()
        m.vars[i] <<= v

    else if (op = &h17) then
        i = getByte()
        v = getShort()
        m.vars[i] >>= v
        
    else if (op = &h18) then
        skipBytes(5)
        
    else if (op = &h19) then
        skipBytes(2)
        
    else if (op = &h1a) then
        skipBytes(5)
    
    endif

end sub

sub executeScripts()
    for i = 0 to 63
        if m.paused[i] = 0 and m.vectors[i] <> &hffff
            m.pc = m.vectors[i]
            m.stack = []
            executeScript()
            m.vectors[i] = m.pc
        end if
    end for
end sub

sub gameTick()
    if not m.end then
        updateKeyboard()
        rotateVectors()
        executeScripts()
    end if
end sub

sub timerTick()
    if m.useTimer then
        if m.stopAtFrame > 0 then
           m.stopAtFrame--
           if m.stopAtFrame = 0 then
               m.end = true
           end if 
        end if
        gameTick()
    end if
end sub
