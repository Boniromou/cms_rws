function getMachineId(){
  params= window.location.search.replace("?", "");
  terminal_id = params.replace("terminal_id=","");
  return terminal_id;
}
