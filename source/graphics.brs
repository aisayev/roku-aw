' Roku Another World (or, Out of This World) Experiment Channel - http://github.com/aisayev/roku-aw
' Brightscript remake developed by Artyom Isayev (Artem Isaiev)

sub initScreens()
    m.port = CreateObject("roMessagePort")
    di = CreateObject("roDeviceInfo")
    
    if (di.GetUIResolution().name <> "sd") then
            m.mainScreen = CreateObject("roScreen", true, 854, 480)
            drwRegions = dfSetupDisplayRegions(m.mainScreen, 107, 40, 640, 400)
    else
            m.mainScreen = CreateObject("roScreen", true, 640, 480)
            drwRegions = dfSetupDisplayRegions(m.mainScreen, 0, 40, 640, 400)
    end if
    
    m.gameScreen = drwRegions.main
      
    m.mainScreen.SetMessagePort(m.port)
    m.mainScreen.Clear(0)
    m.gameScreen.Clear(0)
    m.gameScreen.Finish()
    m.mainScreen.SwapBuffers()

    m.gameScreens = []

    for i = 0 to 3
        m.gameScreens[i] = CreateObject("roBitmap", {width:640, height:400, AlphaEnable:false})
        m.gameScreens[i].Clear(0)
        m.gameScreens[i].Finish()
    end for
    
    m.currentPage3 = 1
    m.currentPage2 = 2
    m.currentPage1 = m.currentPage2

end sub

function getScreenAddress(screen)
    if ((screen >= 0) and (screen <= 3)) then
        c = screen
    else if (screen = &hff) then
        c = m.currentPage3
    else if (screen = &hfe) then
        c = m.currentPage2
    else
        c = 0
    endif
    return c
end function

sub clearScreen()
    m.gameScreen.Clear(0)
    m.gameScreen.Finish()
    m.mainScreen.Clear(0)
    m.mainScreen.SwapBuffers()
    sleep(500)
end sub

sub fillScreen(screen, color)
    screen = getScreenAddress(screen)
    m.gameScreens[screen].Clear(getPaletteColor(color))
end sub

sub updateDisplay(src)

    src = getScreenAddress(src)
    m.gameScreens[src].Finish()
    m.gameScreen.DrawObject(0, 0, m.gameScreens[src])
    m.gameScreen.Finish()
    m.mainScreen.SwapBuffers()
    
end sub

function getPaletteColor(index)
    ptr = (m.curPalette * 32) + (index * 2)
    c1 = m.file023[ptr]
    c2 = m.file023[ptr+1]
    r = ((c1 and &h0f) << 4) + (c1 and &hf)
    g = (c2 and &hf0) + (c2 >> 4)
    b = ((c2 and &h0f) << 4) + (c2 and &hf)
    c = (r << 24) + (g << 16) + (b << 8)
    return c
end function

sub fillPolygon(off, color, zoom, x, y)

        zoom2 = zoom / 64
        bbw = getGraphicsByteAt(off) * zoom2
        off++
        bbh = getGraphicsByteAt(off) * zoom2
        off++
        npoints = getGraphicsByteAt(off)
        off++
        
        maxx = 0
        maxy = 0
        
        points = []
        for i = 0 to (npoints-1)
            tx = getGraphicsByteAt(off) * zoom2 * 2
            off++
            ty = getGraphicsByteAt(off) * zoom2 * 2 
            off++
            points[i] = {x: cint(tx), y: cint(ty)}
            if tx > maxx then maxx = tx
            if ty > maxy then maxy = ty
        end for
        
        x1 = cint(x*2 - bbw)
        x2 = cint(x*2 + bbw)
        y1 = cint(y*2 - bbh)
        y2 = cint(y*2 + bbh)

        if (not (x1 > 639 or x2 < 0 or y1 > 399 or y2 < 0)) then
            screen = m.currentPage1
            fillStyle = getPaletteColor(color)

        
            if (npoints = 4 and bbw = 0 and bbh = 1) then
                m.gameScreens[screen].DrawRect(x1, y1, 2, 2, fillStyle)    
            else
                nodeX = []
                for pixelY = 0 to maxy
                    nodes = 0
                    j = npoints - 1
                    for i = 0 to (npoints-1)
                        if ((points[i].y < pixelY and points[j].y >=  pixelY) or (points[j].y <  pixelY and points[i].y >= pixelY)) then
                            nodeX[nodes] = cint(points[i].x + (pixelY - points[i].y ) / (points[j].y - points[i].y) * (points[j].x- points[i].x))
                            nodes++
                        end if
                        j = i
                    end for 
                
                    nodeX.sort()
                    
                    for i = 0 to (nodes - 1) step 2
                       if (nodeX[i] > maxx) then 
                            exit for
                       end if
                       if (nodeX[i + 1] > 0) then
                            
                            if (nodeX[i] < 0) then nodeX[i] = 0
                            
                            if (nodeX[i + 1] > maxx) then nodeX[i + 1] = maxx
                            
                            m.gameScreens[screen].DrawRect(x1 + nodeX[i], y1 + pixelY, nodeX[i + 1] - nodeX[i], 1, fillStyle)
                            
                       end if
                    end for                
                end for
                
            endif
        
        endif
end sub

sub drawShape(off, color, zoom, x, y)
    i = getGraphicsByteAt(off)
    off++
    if (i >= &hc0) then
        if (color and &h80) then
            color = i and &h3f
        endif
        color = color and &hf
        fillPolygon(off, color, zoom, x, y)
    else
        i = i and &h3f
        if (i = 2) then
            drawShapeParts(off, zoom, x, y)
        endif
        
    endif    
end sub

sub drawShapeParts(off, zoom, x, y)
    cx = x - (getGraphicsByteAt(off) * zoom / &h40)
    off++
    cy = y - (getGraphicsByteAt(off) * zoom / &h40)
    off++
    n = getGraphicsByteAt(off)
    off++

    while (n >= 0)
        off2 = (getGraphicsByteAt(off) << 8) or getGraphicsByteAt(off+1)
        off += 2

        px = cx + (getGraphicsByteAt(off) * zoom / &h40)
        off++
        py = cy + (getGraphicsByteAt(off) * zoom / &h40)
        off++
        color = &hff
        bp = off2
        off2 = off2 and &h7fff
        if (bp and &h8000) then
            color = getGraphicsByteAt(off) and &h7f
            off += 2
        endif

        off2 = (off2<<1) and &hffff
        
        drawShape(off2, color, zoom, px, py)

        n--
    end while
end sub

function getGraphicsByteAt(off)
    if m.useAux then
        c = m.file017[off]
    else
        c = m.file025[off]
    endif
    return c
end function

sub copyScreen(src, dst)
    if (src > 3 and src < &hfe) then
       src = src and 3
    endif

    src = getScreenAddress(src)
    dst = getScreenAddress(dst)

    if (src <> dst) then
        m.gameScreens[src].Finish()
        m.gameScreens[dst].DrawObject(0, 0, m.gameScreens[src])
        m.gameScreens[dst].Finish()
    endif

end sub

sub drawChar(ch, x, y, rgb)
    off = (asc(ch) - 32)*8
    for  _y = 0 to 7    
        for _x = 0 to 7
            b = (m.font[off+_y] << _x) and &h80
                if (b) then
                    m.gameScreens[m.currentPage1].DrawRect(x+_x, y+_y, 1, 1, rgb)
                end if
        end for
    end for
end sub

sub drawString(index, x, y, c)
    rgb = getPaletteColor(c)
    for i =  0 to  (m.gameStrings.count() - 1)
        if  m.gameStrings[i][0] = index then
            s = m.gameStrings[i][1]
            for j = 0 to s.len() 
                    drawChar(mid(s, j , 1), x+j*8, y, rgb)
            end for
            exit for
        end if
    end for
end sub
