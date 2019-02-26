--[[----------------------------------------------------------------------------

FtpUploadTask.lua
Upload photos via Ftp

--------------------------------------------------------------------------------

ADOBE SYSTEMS INCORPORATED
 Copyright 2007 Adobe Systems Incorporated
 All Rights Reserved.

NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.

------------------------------------------------------------------------------]]

-- Lightroom API
local LrPathUtils = import 'LrPathUtils'
local LrFtp = import 'LrFtp'
local LrFileUtils = import 'LrFileUtils'
local LrErrors = import 'LrErrors'
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrHttp = import "LrHttp"
local LrTasks = import "LrTasks"
local LrApplication = import "LrApplication"
--============================================================================--

local catalog = LrApplication.activeCatalog()

FtpUploadTask = {}

local myLogger = LrLogger( 'exportLogger' )
myLogger:enable( "print" ) -- Pass either a string or a table of actions.
local function outputToLog( message )
	myLogger:trace( message )
end
--------------------------------------------------------------------------------

function sendHttp(path)
	outputToLog(catalog:getName())
	--trasformazione del messaggio in JSON--
	local message= '{"pathFile" : "'..path..'", "images":['
	for a, b in ipairs(catalog:getActiveSources()) do
		--outputToLog("Active Folders: "..b:getName())
		--per tutte le foto della cartella--
		for _, photo in ipairs(b:getPhotos()) do
			--prendo il nome e i keywords--
			message=message..'{"fileName" : "'..photo:getFormattedMetadata("fileName")..'","tags" : [ '
			--itero in ogni keyword (sono separati da spazi)--
			for tag in string.gmatch( photo:getFormattedMetadata('keywordTags'), "%a+") do 
				message=message..'"'..tag..'", '
			end
			message=message:sub(1, -3).." ]},"
		end
	end
	message=message:sub(1, -2).."]}"
	--outputToLog("Message\n"..message)
	--LrTasks.startAsyncTask(function() sendPost(message) end)
end

function sendPost(message)
	local headers = {
		{ field= 'Content-Type', value= 'application/json'} 
	}
	outputToLog("Messaggio:\n"..message)
	local result, hdrs = LrHttp.post( "http://localhost:80/prova/index.php", message, headers)
	if(result==nil) then
		outputToLog("no results")
	else
		outputToLog("Response by the server received:\n"..result)
	end
end

function FtpUploadTask.processRenderedPhotos( functionContext, exportContext )

	-- Make a local reference to the export parameters.
	
	local exportSession = exportContext.exportSession
	local exportParams = exportContext.propertyTable
	local ftpPreset = exportParams.ftpPreset

	-- Set progress title.

	local nPhotos = exportSession:countRenditions()

	local progressScope = exportContext:configureProgress {
						title = nPhotos > 1
							   and LOC( "$$$/FtpUpload/Upload/Progress=Uploading ^1 photos via Ftp", nPhotos )
							   or LOC "$$$/FtpUpload/Upload/Progress/One=Uploading one photo via Ftp",
					}

	-- Create an FTP connection.
	
	if not LrFtp.queryForPasswordIfNeeded( ftpPreset ) then
		return
	end
	
	local ftpInstance = LrFtp.create( ftpPreset, true )
	
	if not ftpInstance then
	
		-- This really shouldn't ever happen.
		
		LrErrors.throwUserError( LOC "$$$/FtpUpload/Upload/Errors/InvalidFtpParameters=The specified FTP preset is incomplete and cannot be used." )
	end
	
	-- Ensure target directory exists.
	
	local index = 0
	while true do
		
		local subPath = string.sub( exportParams.fullPath, 0, index )

		ftpInstance.path = subPath
		
		local exists = ftpInstance:exists( '' )
		
		if exists == false then
			local success = ftpInstance:makeDirectory( '' )
			
			if not success then
			
				-- This is a possible situation if permissions don't allow us to create directories.
				
				LrErrors.throwUserError( LOC "$$$/FtpUpload/Upload/Errors/CannotMakeDirectoryForUpload=Cannot upload because Lightroom could not create the destination directory." )
			end
			
		elseif exists == 'file' then
		
			-- Unlikely, due to the ambiguous way paths for directories get tossed around.
			
			LrErrors.throwUserError( LOC "$$$/FtpUpload/Upload/Errors/UploadDestinationIsAFile=Cannot upload to a destination that already exists as a file." )
		elseif exists == 'directory' then
		
			-- Excellent, it exists, do nothing here.
			
		else
		
			-- Not sure if this would every really happen.
			
			LrErrors.throwUserError( LOC "$$$/FtpUpload/Upload/Errors/CannotCheckForDestination=Unable to upload because Lightroom cannot ascertain if the target destination exists." )
		end
		
		if index == nil then
			break
		end
		
		index = string.find( exportParams.fullPath, "/", index + 1 )
		
	end

	ftpInstance.path = exportParams.fullPath
	
	-- Iterate through photo renditions.
	
	local failures = {}

	for _, rendition in exportContext:renditions{ stopIfCanceled = true } do
	
		-- Wait for next photo to render.

		local success, pathOrMessage = rendition:waitForRender()
		
		-- Check for cancellation again after photo has been rendered.
		
		if progressScope:isCanceled() then break end
		
		if success then

			local filename = LrPathUtils.leafName( pathOrMessage )
			
			local success = ftpInstance:putFile( pathOrMessage, filename )
			
			if not success then
			
				-- If we can't upload that file, log it.  For example, maybe user has exceeded disk
				-- quota, or the file already exists and we don't have permission to overwrite, or
				-- we don't have permission to write to that directory, etc....
				
				table.insert( failures, filename )
			end
					
			-- When done with photo, delete temp file. There is a cleanup step that happens later,
			-- but this will help manage space in the event of a large upload.
			
			LrFileUtils.delete( pathOrMessage )
					
		end
		
	end
	LrTasks.startAsyncTask(function() sendHttp(exportParams.fullPath) end)
	ftpInstance:disconnect()
	
	if #failures > 0 then
		local message
		if #failures == 1 then
			message = LOC "$$$/FtpUpload/Upload/Errors/OneFileFailed=1 file failed to upload correctly."
		else
			message = LOC ( "$$$/FtpUpload/Upload/Errors/SomeFileFailed=^1 files failed to upload correctly.", #failures )
		end
		LrDialogs.message( message, table.concat( failures, "\n" ) )
	end
	
end
