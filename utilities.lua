--------------------------------------------------------------------------------
--    Utilities Libraries
--
-- Changelog:
--     03/01/2012        Added FluentUO, and findBodBookWithName,
--                       findTailorBods, findSmithBods, moveBodToBook     
--     03/04/2012        Changed the restartClient wait time from 10s to 20s                  
--   0.1.1
--     03/06/2012        Added getTargetItem
--   0.1.2
--     03/06/2012        Added dropBodFromBook, findBods, doubleClickObject
--   0.1.3
--     03/07/2012        Added gumpAppearedWithId(gumpId, delay), waitForBodBook(delay)
--                       function openBodBook(book), and import the journal scan
--                       lib from Kal In Ex, url: http://www.easyuo.com/forum/viewtopic.php?t=43488
--------------------------------------------------------------------------------
dofile("FluentUO.lua")
dofile("journal.lua")

-- Wait for particular gump for some time
function gumpAppeared(gumpName, delay)
  if delay == nil then
    delay = 30000
  end
  local timeout = getticks() + delay
  repeat
    if getticks() < timeout then
      wait(50)
    else
      return false
    end
  until UO.ContName == gumpName
  return true
end

-- Wait for particular gump for some time
function gumpAppearedWithId(gumpId, delay)
  if delay == nil then
    delay = 30000
  end
  local timeout = getticks() + delay
  repeat
    if getticks() < timeout then
      wait(50)
    else
      return false
    end
  until UO.ContID == gumpId
  return true
end

function currentTime()
  local nHour, nMinute, nSecond = gettime()
  local hh, mm, ss
  if nHour < 10 then
    hh = "0"..nHour
  else
    hh = nHour
  end
  if nMinute < 10 then
    mm = "0"..nMinute
  else
    mm = nMinute
  end
  if nSecond < 10 then
    ss = "0"..nSecond
  else
    ss = nSecond
  end
  return hh..":"..mm..":"..ss
end

function log(value)
  if value == nil then
    print(currentTime()..": nil")
  else
    print(currentTime()..": "..value)
  end
end

function restartClient(msg)
  if msg ~= nil then
    log(msg)
  end
  local f = openfile("kill_them_all.txt", "w")
  f:flush()
  f:close()
  wait(20000)
  UO.CliNr=1
end

--  Find Bulk Order Book named with "name".
--      return item table from FluentUO lib.
function findBodBookWithName(name)
  return Backpack().WithType(8793).WithProperty("Book Name").EqualTo(name).Items[1]
end

function findTailorBods()
  return Backpack().WithType(8792).WithCol(1155).Items
end

function findSmithBods()
  return Backpack().WithType(8792).WithCol(1102).Items
end

function findBods()
  return Backpack().WithType(8792).Items
end

function moveBodToBook(bods, book)
  if bods == nil or book == nil or #bods == 0 then
    return
  end
  local bodtype
  if bods[1].Col == 1155 then
    bodtype = "tailor"
  elseif bods[1].Col == 1102 then 
    bodtype = "smith"
  end
  log("Moving "..#bods.." "..bodtype.." bods to "..book.Property["Book Name"])
  for i = 1, #bods do
    UO.Drag(bods[i].ID)
    wait(100)
    UO.DropC(book.ID)
    wait(1000)
    gumpAppeared("generic gump")
  end
end

function getTargetItem(delay)
  UO.TargCurs = true

  if delay == nil or delay == 0 then
    delay = 30000
  end
  local timeout = getticks() + delay
  repeat
    if getticks() < timeout then
      wait(50)
    else
      return nil
    end
  until UO.TargCurs == false
  
  local item = World().WithID(UO.LTargetID).Items[1]

  return item
end

function doubleClickObject(objectId)
  local tmpId = UO.LObjectID
  if objectId ~= nil then
    UO.LObjectID = objectId
    UO.Macro(17, 0)
  end
  UO.LObjectID = tmpId
end

-- Wait for the bod book open. Returns true if book is open, or false if the book
-- can not be open
function waitForBodBook(delay)
  if delay == nil then
    delay = 30000
  end
  local myJournal = journal.new()
  local timeout = getticks() + delay
  repeat
    -- First, check jounal for empty book
    local text = myJournal:next()
    if text ~= nil and (text:match("The book is empty") ~= nil) then
      -- the book is empty
      return false
    end
    if getticks() < timeout then
      wait(50)
    else
      return false
    end
  until UO.ContName == "generic gump"
  return true
end

-- Open specified bod book until it is open or it is an empty book.
-- If it is an empty book, this will return false, otherwise true
function openBodBook(book)
  -- First, open that backpack
  UO.Macro(8, 7)
  if gumpAppearedWithId(1086632648) then
    -- Then, try openning the book
    doubleClickObject(book.ID)
    return waitForBodBook()
  else
    return false
  end
end

-- Drop the first bod from the given bod book. Returns nil if book is empty
function dropBodFromBook(book)
  if book == nil then
    return nil
  end
  
  -- First, double click the book
  doubleClickObject(book.ID)
  if not gumpAppeared("generic gump", 15) then
  end
end