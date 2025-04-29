-- Extensions for the os module
local os = os or {}

-- os.stime: Returns the current timestamp in seconds (equivalent to os.time)
function os.stime()
    return os.time()
end

-- os.sdate: Formats a date like os.date, with a customizable format
function os.sdate(format, time)
    return os.date(format, time or os.time())
end

-- Ensure functions are available globally
_G.os.stime = os.stime
_G.os.sdate = os.sdate