-------------------------------------------------------------------------------
--  Script Name: Transplace BOD
--
--
--
--

-- Load libraries
dofile("utilities.lua")

-- Global variables
local form, btnSourceBook, lblSourceBook, btnTargetBook, lblTargetBook

local sourceBook, targetBook

-- GUI methods
function onClose()
  Obj.Exit()
end

function freeElements()
  Obj.Free(form)             --release object from memory
  Obj.Free(btnSourceBook)
  Obj.Free(lblSourceBook)
  Obj.Free(btnTargetBook)
  Obj.Free(lblTargetBook)
end

function onClickSourceBook()
  local item = getTargetItem()
  if item ~= nil and item.Type == 8793 then
    if not (item.Property["Book Name"] == nil or #item.Property["Book Name"] == 0) then
      lblSourceBook.Caption = item.Name..":"..item.Property["Book Name"]
    else
      lblSourceBook.Caption = item.Name
    end
    sourceBook = item
  else
    sourceBook = nil
    lblSourceBook.Caption = "N/A"
  end
end

function onClickTargetBook()
  local item = getTargetItem()
  if item ~= nil and item.Type == 8793 then
    if not (item.Property["Book Name"] == nil or #item.Property["Book Name"] == 0) then
      lblTargetBook.Caption = item.Name..":"..item.Property["Book Name"]
    else
      lblTargetBook.Caption = item.Name
    end
    targetBook = item
  else
    targetBook = nil
    lblTargetBook.Caption = "N/A"
  end
end

function main()
  form = Obj.Create("TForm") --create a TForm object 
  form.OnClose = onClose
  form.Caption = "BOD Transplacer"
  form.FormStyle = 3              -- always on top

  -- Button to choose source book
  btnSourceBook = Obj.Create("TButton")   --create a TButton object 
  btnSourceBook.Caption = "Source Book"          --assign button text 
  btnSourceBook.OnClick = onClickSourceBook --assign event handler function 
  btnSourceBook.Parent = form             --IMPORTANT: button is placed on form!
  btnSourceBook.Top = 10
  btnSourceBook.Left = 10
  
  lblSourceBook = Obj.Create("TLabel")
  lblSourceBook.Caption = "N/A"
  lblSourceBook.Top = btnSourceBook.Top + (btnSourceBook.Height - lblSourceBook.Height) / 2
  lblSourceBook.Left = btnSourceBook.Left + btnSourceBook.Width + 15
  lblSourceBook.Parent = form
  
  -- Button to choose target book
  btnTargetBook = Obj.Create("TButton")   --create a TButton object 
  btnTargetBook.Caption = "Target Book"          --assign button text 
  btnTargetBook.OnClick = onClickTargetBook --assign event handler function 
  btnTargetBook.Parent = form             --IMPORTANT: button is placed on form!
  btnTargetBook.Top = 10 + btnSourceBook.Top + btnSourceBook.Height
  btnTargetBook.Left = 10
  
  lblTargetBook = Obj.Create("TLabel")
  lblTargetBook.Caption = "N/A"
  lblTargetBook.Top = btnTargetBook.Top + (btnTargetBook.Height - lblTargetBook.Height) / 2
  lblTargetBook.Left = btnTargetBook.Left + btnTargetBook.Width + 15
  lblTargetBook.Parent = form

  form.Show()                
  Obj.Loop()                 
  freeElements()
end

main()