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
}
