dofile("utilities-0.1.3.lua")

local myJournal = journal.new()
local book = findBodBookWithName("Small1")
if book ~= nil then
  log("Openning book: "..book.Property["Book Name"].."\t"..book.ID)
  if openBodBook(book) then
    log("Openned")
  else
    log("Empty book")
  end
else
  log("NONE!")
end