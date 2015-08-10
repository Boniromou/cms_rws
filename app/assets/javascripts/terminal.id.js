function getTerminalID()
{ 
	var fp = new Fingerprint();
 	var terminalID = fp.get();
   	return terminalID;
}