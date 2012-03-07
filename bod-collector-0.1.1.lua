dofile("utilities.lua")

--------------------------------------------------------------------------------
--    Helper Methods
--
-- Changelog:
--     03/01/2012        changed the getBODs, to move bod after got them                                                                                                                                                 
--------------------------------------------------------------------------------

-- Login with the specified character
-- return
--       true, false whether successed
--       delay, how many
function login(account, charIndex)
  -- Assure the start screen to be MainMenu
  if UO.ContName ~= "MainMenu gump" and UO.ContName ~= "Login gump" then
    log("Restart before running script.")
    restartClient()
  end

  log("Authenticating: " .. account.username)
  -- First, enter the username and password and press enter
  UO.Click(522, 360, true, true, true, false)
  for i = 1, 20 do
    UO.Key("BACK")
  end
  wait(10) -- BUG. You have to wait, or the next message will be overwritten
  UO.Msg(account.username)
  wait(10)
  UO.Click(500, 407, true, true, true, false)
  for i = 1, 20 do
    UO.Key("BACK")
  end
  wait(10) -- BUG. You have to wait, or the next message will be overwritten
  UO.Msg(account.password)
  wait(10)
  UO.Key("ENTER")
  
  -- Wait until the normal gump
  if not gumpAppeared("normal gump") then
    log("Authentication failed.")
    return false, true, 0
  end
  
  -- Try select the last entered shard
  UO.Key("ENTER")
  if not gumpAppeared("Login gump") then
    log("Login failed.")
    return false, true, 0
  end
  
  -- Select the character at the specified slot
  local y = 140 + (charIndex - 1) * 40
  UO.Click(360, y, true, true, true, false)
  wait(150)
  UO.Click(618, 444, true, true, true, false)
  local timeout = getticks() + 30000
  repeat
    if getticks() < timeout then
      wait(500)
    else
      -- Check if it is because the status bar not open
      if UO.ContName ~= "waiting gump" then
        UO.Macro(8, 2)
        timeout = timeout + 3000
      else
        local delay = account.lastLogOut + 300000 - getticks()
        log("Login failed. Have to wait "..(delay / 60000).." minutes.")
        return false, false, delay
      end
    end
  until UO.CharName ~= ""
  log("Login successed. Char: "..UO.CharName)
  return true
end

function fillChars(accounts)
  local characters = {}
  local count = 1
  for i = 1, 7 do
    for j = 1, #accounts do
      -- Only add the current index when current account has a char at this slot
      if accounts[j].chars >= i then
        characters[count] = {account = accounts[j], charIndex = i}
        count = count + 1
      end
    end
  end
  return characters
end

function getBODs()
  UO.Key("F10")
  wait(5000)
  UO.Key("F11")
  wait(5000)
  
  -- After got the bod, try to move the bod into book
  local tailorBook = findBodBookWithName("Tailor")
  if tailorBook ~= nil then
    log("Tailor book deeds: "..tailorBook.Property["Deeds In Book"])
  end
  moveBodToBook(findTailorBods(), tailorBook)
  
  local smithBook = findBodBookWithName("Smith")
  if smithBook ~= nil then
    log("Smith book deeds: "..smithBook.Property["Deeds In Book"])
  end
  moveBodToBook(findSmithBods(), smithBook)
end

function logout(account)
  wait(10000) -- Wait 5 seconds for all openning gump
  UO.Macro(8, 1)
  if gumpAppeared("paperdoll gump", 2000) then
    UO.Click(UO.ContPosX + 216, UO.ContPosY + 108, true, true, true, false)
    if gumpAppeared("YesNo gump", 1000) then
      UO.Click(UO.ContPosX + 125, UO.ContPosY + 85, true, true, true, false)
      if gumpAppeared("MainMenu gump", 1000) then
        log("Logged out.")
      else
        restartClient("Logout failed. Restart client.")
      end
    else
      restartClient("Logout failed. YesNo didn't show up. Restart client.")
    end
  else
    restartClient("Logout failed. Paper doll didn't show up. Restart client.")
  end
  account.lastLogOut = getticks()
end

--------------------------------------------------------------------------------
--    Variables Initialization                                                                                                                                                
--------------------------------------------------------------------------------

local accounts = {
  {username = "yunjia0", password = "jackjia", chars = 7, lastLogOut = getticks()},
  {username = "yunjia1", password = "jackjia", chars = 7, lastLogOut = getticks()},
  {username = "yunjia2", password = "jackjia", chars = 7, lastLogOut = getticks()},
  {username = "yunjia3", password = "jackjia", chars = 7, lastLogOut = getticks()}
}

local testCharacters = {
  [1] = {
    account = accounts[1],
    charIndex = 1
  },
  [2] = {
    account = accounts[2],
    charIndex = 2
  },
  [3] = {
    account = accounts[3],
    charIndex = 1
  },
  [4] = {
    account = accounts[4],
    charIndex = 1
  }
}

--local initDelay = 13 * 60000

--------------------------------------------------------------------------------
--    Main Procedure                                                                                                                                                
--------------------------------------------------------------------------------

function main()
  local chars = fillChars(accounts)
  --chars = testCharacters
  local firstBod
  if initDelay ~= nil then
    wait(initDelay)
  end
  repeat
    for i = 1, #chars do
      local success, restart, delay
      repeat -- Keep login until success, and wait for delay if neccessary
        success, restart, delay = login(chars[i].account, chars[i].charIndex)
        if not success then
          if restart then
            restartClient()
          else
            UO.Key("ENTER")
            if not gumpAppeared("Login gump", 1000) then
              restartClient()
	    end
          end 
          wait(delay)
        end
      until success
      
      getBODs()
      if i == 1 then
        log("Got first BOD.")
	firstBod = getticks()
      end
      
      logout(chars[i].account)
    end
    log("Finished one round.")
    local tmp = firstBod + 3720000 - getticks()
    if tmp > 0 then
      log("Need to wait: "..(tmp / 60000).." minutes.")
      wait(tmp)
    end
  until false  
end

main()
stop()