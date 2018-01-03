//=require plugin/datatables/jquery.dataTables.min
//=require plugin/datatables/dataTables.bootstrap.min
$(document).ready(function() {
  $('#datatable_col_reorder').dataTable({
  	"pageLength": 50
  	});

  $('#account_activities_table').dataTable({
      "scrollX": true,
      "order": [[ 0, "desc"]],
      "pageLength": 50,
    });
})
