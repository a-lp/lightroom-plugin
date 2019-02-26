--[[----------------------------------------------------------------------------

FtpUploadExportServiceProvider.lua
Export service provider description for Lightroom FtpUpload uploader

--------------------------------------------------------------------------------

ADOBE SYSTEMS INCORPORATED
 Copyright 2007 Adobe Systems Incorporated
 All Rights Reserved.

NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.

------------------------------------------------------------------------------]]

-- FtpUpload plug-in
require "FtpUploadExportDialogSections"
require "FtpUploadTask"

local LrApplication = import "LrApplication"
local LrLogger = import 'LrLogger'
local LrHttp = import "LrHttp"
local LrTasks = import "LrTasks"
local LrFunctionContext = import "LrFunctionContext"

--============================================================================--

local catalog = LrApplication.activeCatalog()

-- Debugger

local myLogger = LrLogger( 'exportLogger' )
myLogger:enable( "print" ) -- Pass either a string or a table of actions.
local function outputToLog( message )
	myLogger:trace( message )
end

-- Funzioni per caricamento delle keywords su database tramite messaggio POST

-- function sendPost(message)
-- 	local headers = {
-- 		{ field= 'Content-Type', value= 'application/json'} 
-- 	}

-- 	local result, hdrs = LrHttp.post( "http://localhost:80/prova/index.php", message, headers)
-- 	if(result==nil) then
-- 		outputToLog("no results")
-- 	else
-- 		outputToLog("Response by the server received:\n"..result)
-- 	end
-- end

-- function uploadCollection()
-- 	--trasformazione del messaggio in JSON--
-- 	local message= '\n{ "images":['
-- 	for a, b in ipairs(catalog:getActiveSources()) do
-- 		outputToLog("Active Folders: "..b:getName())
-- 		--per tutte le foto della cartella--
-- 		for _, photo in ipairs(b:getPhotos()) do
-- 			--prendo il nome e i keywords--
-- 			message=message..'\n\t{\n\t\t"fileName" : "'..photo:getFormattedMetadata("fileName")..'",\n\t\t"tags" : [ '
-- 			--itero in ogni keyword (sono separati da spazi)--
-- 			for tag in string.gmatch( photo:getFormattedMetadata('keywordTags'), "%a+") do 
-- 				message=message..'"'..tag..'", '
-- 			end
-- 			message=message:sub(1, -3).." ]\n\t},"
-- 		end
-- 	end
-- 	message=message:sub(1, -2).."\n]}"
-- 	outputToLog("Preparing message to send to the server via POST")
-- 	LrTasks.startAsyncTask(function() sendPost(message) end)
-- end

-- Invio tag al server
--------------------------------------------------------------------------------
return {
	
	hideSections = { 'exportLocation' },

	allowFileFormats = nil, -- nil equates to all available formats
	
	allowColorSpaces = nil, -- nil equates to all color spaces

	exportPresetFields = {
		{ key = 'putInSubfolder', default = false },
		{ key = 'path', default = 'photos' },
		{ key = "ftpPreset", default = nil },
		{ key = "fullPath", default = nil },
	},

	startDialog = FtpUploadExportDialogSections.startDialog,
	sectionsForBottomOfDialog = FtpUploadExportDialogSections.sectionsForBottomOfDialog,
	
	processRenderedPhotos = FtpUploadTask.processRenderedPhotos,
	-- Invio tag al server
	--outputToLog("FTP: Invio metadati"),
	--LrTasks.startAsyncTask(uploadCollection),
}
