' Roku Another World (or, Out of This World) Experiment Channel - http://github.com/aisayev/roku-aw
' Brightscript remake developed by Artyom Isayev (Artem Isaiev)

Library "v30/bslDefender.brs"

function main() as void
    m.code = bslUniversalControlEventCodes()
    m.pc = 0
    m.stack = [] 
    m.vectors = CreateObject("roArray",64,true)
    m.vectors2 = CreateObject("roArray",64,true)
    m.paused = CreateObject("roArray",64,true)
    m.paused2 = CreateObject("roArray",64,true)
    m.vars = []
    m.useTimer = true
    m.stopAtFrame = 0
    m.end = false
    m.useAux = false
    m.halt = false
    m.curPalette = 0
    m.keyMask = 0
    m.button = 0
    m.DIR_LEFT = 1
    m.DIR_UP = 2
    m.DIR_DOWN = 4
    m.DIR_RIGHT = 8
    
    preloadScripts()
    initScripts()
    initScreens()
    
    timer = CreateObject("roTimespan")
    
    while(true)

        event = m.port.GetMessage()
        
        if type(event) = "roUniversalControlEvent" then
            id = event.GetInt()
            ? id
            if id = m.code.BUTTON_BACK_PRESSED then
               m.end = true
               exit while
            else if id = m.code.BUTTON_PLAY_PRESSED then
                m.useTimer = not m.useTimer
            else if id = m.code.BUTTON_LEFT_PRESSED then
                m.keyMask = m.keyMask or m.DIR_LEFT
            else if id = m.code.BUTTON_LEFT_RELEASED then 
                m.keyMask = m.keyMask and not m.DIR_LEFT
            else if id = m.code.BUTTON_RIGHT_PRESSED then
                m.keyMask = m.keyMask or m.DIR_RIGHT
            else if id = m.code.BUTTON_RIGHT_RELEASED then 
                m.keyMask = m.keyMask and not m.DIR_RIGHT
            else if id = m.code.BUTTON_DOWN_PRESSED then
                m.keyMask = m.keyMask or m.DIR_DOWN
            else if id = m.code.BUTTON_DOWN_RELEASED then 
                m.keyMask = m.keyMask and not m.DIR_DOWN
            else if id = m.code.BUTTON_UP_PRESSED then
                m.keyMask = m.keyMask or m.DIR_UP
            else if id = m.code.BUTTON_UP_RELEASED then 
                m.keyMask = m.keyMask and not m.DIR_UP
            else if id = m.code.BUTTON_INSTANT_REPLAY_PRESSED then
                m.button = 1
            else if id = m.code.BUTTON_INFO_PRESSED then
                 m.button = 0
            else if id = m.code.BUTTON_REWIND_PRESSED then
                 m.keyMask = m.keyMask or m.DIR_DOWN
            else if id = m.code.BUTTON_FAST_FORWARD_PRESSED then
                  m.keyMask = m.keyMask and not m.DIR_DOWN
            else if id = m.code.BUTTON_SELECT_PRESSED then
                m.button = 1
            else if id = m.code.BUTTON_SELECT_RELEASED then
                m.button = 0
            endif
        endif

        timer.Mark()
        timerTick()

        delay = 84 - timer.TotalMilliseconds()
        if (delay > 0) then sleep(delay)

    end while
    
    clearScreen()
    return
    
end function