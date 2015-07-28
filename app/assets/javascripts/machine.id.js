function getMachineId(){
  params= window.location.search.replace("?", "");
  machine_id = params.replace("machine_id=","");
  return machine_id;
}
