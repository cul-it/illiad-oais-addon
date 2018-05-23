-- About OASISOU.lua
--
-- OASISOU.lua does an OASIS search for the ISBN for loans
-- using the OPENURL feature of OASIS.
-- scriptActive must be set to true for the script to run.
-- autoSearch (boolean) determines whether the search is performed automatically when a request is opened or not.
--
-- set autoSearch to true for this script to automatically run the search when the request is opened.
-- based on GOBI from IDS Project
--
require "Atlas.AtlasHelpers" ;

local autoSearch = GetSetting("AutoSearch");
local scriptActive = GetSetting("Active");
local username= GetSetting("Username");
local password= GetSetting("Password");
local url = GetSetting("URL");
local debugEnabled = true;

local interfaceMngr = nil;
local browser = nil;

function Init()
  if scriptActive then
    if GetFieldValue("Transaction", "RequestType") == "Loan" then
      interfaceMngr = GetInterfaceManager();
      -- Create browser
      browser = interfaceMngr:CreateBrowser("OASISOU", "OASISOU", "Script");
      -- Imports price from first Item in list.
      browser:CreateButton("Import Price", GetClientImage("Search32"), "ImportPrice", "OASIS");
      browser:CreateButton("Search Title", GetClientImage("Search32"), "SearchTitle", "OASIS");
      browser:CreateButton("SearchISxN", GetClientImage("Search32"), "SearchISBN", "OASIS");
      browser:Show();
      if autoSearch then
        Search();
      end
    end
  end
end

function Search()
  Log("entered Search"); 
  browser:RegisterPageHandler("formExists", "loginform", "OASISLoaded", false);
  local isXn = GetFieldValue("Transaction", "ISSN");
  Log("isXn is "..  isXn); 
  if isXn:len()<8 then
    -- oup = "title=" .. string.gsub(GetFieldValue("Transaction", "LoanTitle")," ", "%20");
    local ti = GetFieldValue("Transaction", "LoanTitle");
    ti =  ti:gsub(":"," "); 
    oup = "title=" .. AtlasHelpers.UrlEncode(GetFieldValue("Transaction", "LoanTitle"));
    Log("(title) oup=" .. oup);
  else
    Log("(isbn) isXn=" .. isXn);
    if isXn:len()>13 then
      oup = "isbn=" .. isXn:sub(1,13);
    else
      oup = "isbn=" .. isXn; 
    end   
  end
  Log("oup=" .. oup);
  browser:Navigate(url .. oup);
  #browser:Navigate("https://www.couttsoasis.com/openURL?".. oup);
end

function OASISLoaded()
  browser:SetFormValue("loginform", "login_username", username);
  browser:SetFormValue("loginform", "login_password", password);
  browser:ClickObject("login_submit");
  -- browser:SubmitForm("loginform");
 browser:RegisterPageHandler("formExists", "aspnetForm", "StartSearch", false);
end

function StartSearch()
end	


function Log(entry)
	if debugEnabled then 
		LogDebug("OASIS Open URL  ----- " .. entry .. " -----");
	end
end

function SearchTitle()
    local ti = GetFieldValue("Transaction", "LoanTitle");
    browser:SetFormValue("aspnetForm", "txtQuickSearch", ti .. "\r\n");
    browser:RegisterPageHandler("formExists", "aspnetForm", "StartSearch", false);
    browser:SubmitForm("loginform");
end

function SearchISBN()
    local isXn = GetFieldValue("Transaction", "ISSN");
    if isXn:len()>13 then
      oup = isXn:sub(1,13);
    else
      oup = isXn; 
    end   
    browser:SetFormValue("aspnetForm", "txtQuickSearch", oup .. "\r\n");
    browser:RegisterPageHandler("formExists", "aspnetForm", "StartSearch", false);
    browser:SubmitForm("loginform");
end

function ImportPrice()
        Log("entered Import price"); 
	local titleDetails = browser:GetElementInFrame("TabFrame", "TitleDetailsTable");
	if titleDetails == nil then
		return;
	end
        --print("showing  titledetails" .. titleDetails); 
        Log("showing  titledetails"); 
	
	local bElements = titleDetails:GetElementsByTagName("td");
	
	if bElements == nil then
		return;
	end;
        --print("showing  belements" .. bElements); 
        Log("showing  belements"); 
	
	for i=0, bElements.Count - 1 do
		local element = browser:GetElementByCollectionIndex(bElements, i)
		if element:GetAttribute("className") == "valuesFill" then
			local priceText = element.InnerText;
                        Log("showing  valuesFill" .. priceText); 
			if priceText:find("USD") then
			  -- priceText = string.sub(priceText, 2);
			  SetFieldValue("Transaction", "MaxCost", priceText);
			  ExecuteCommand("SwitchTab", {"Detail"});
			  return;
		        end

		end
	end
end
