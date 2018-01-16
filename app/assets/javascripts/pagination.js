//=require plugin/datatables/jquery.dataTables.min
//=require plugin/datatables/dataTables.bootstrap.min
$(document).ready(function() {
  $('#datatable_col_reorder').dataTable({
  	"pageLength": 50
  	});

  $('#account_activity_datatable').dataTable({
      // "scrollX": true,
      "order": [[ 0, "desc"]],
      "serverSide": true,
      "pagingType": 'full_numbers',
      "pageLength": 50,
      "searching": false,
      "columns":[
        {"sortable": true, "width": "9%"},
        {"sortable": true},
        {"sortable": true},
        {"sortable": true},
        {"sortable": false},
        {"sortable": false, "width": "8%"},
        {"sortable": false},
        {"sortable": false},
        {"sortable": false},
        {"sortable": false},
        {"sortable": false, "class": "info"},
        {"sortable": false, "class": "info"},
        {"sortable": false, "class": "danger"},
        {"sortable": false, "class": "danger"},
        {"sortable": false, "class": "success"},
        {"sortable": false, "class": "success"}
      ],
      "ajax": {
        "url": $('#account_activity_datatable').data('source'),
        "complete": function(jqXHR,status){
          if(status == 'success' || status=='notmodified'){
            var result = $.parseJSON(jqXHR.responseText);
            if(result.error_msg){
              $('.dataTables_empty').text(result.error_msg);
            }
          }
        }
      }
    });
})
