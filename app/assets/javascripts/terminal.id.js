function getTerminalID()
{ 
	var fp = new Fingerprint({screen_resolution: true});
 	var terminalID = fp.get();
   	return terminalID;
}