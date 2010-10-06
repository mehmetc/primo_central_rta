/* ****************************************************************************
 *
 * PrimoCentral Real Time Availability Workaround for Primo v3.0
 *
 *
 * Version: 0.1
 *
 * K.U.Leuven/Libis (c) 2010 -- BSD license
 * Mehmet Celik -- mehmet.celik at libis.be
 * 
 */

 (function($) {
    $.limo = {
        primo_central: {
            records: function() {
                var sfx_links = jQuery('.popThumbnailToTop');
                var parameter_hash = {};
                jQuery.each(sfx_links,
                function(i, data) {
                    var params = {};
                    var record_id = jQuery(data).parents('.EXLResult').find(".EXLResultRecordId").attr('id');
                    if (record_id.substring(0, 2) == 'TN') {
                        jQuery.each(data.href.split('&'),
                        function(i, data) {
                            result = data.split('=');
                            params[result[0].replace('rft.', '')] = result[1]
                        });
                        parameter_hash[record_id] = params;
                    }

                });
                return parameter_hash;
            },
            rta: {
				url: 'http://127.0.0.1:3000/',
				update: function(institution_name){
			        var rta_query = {institution: institution_name};
			        var rta_query_length = 0;
			        var all_records = jQuery.limo.primo_central.records();
			        $.each(all_records,
			        function(k, v) {
			            if ((v.issn || v.eissn) && v.date) {
			                var r_id = k;
			                var r_issn = v.issn.replace('-', '');
			                if (r_issn.length == 0) {
			                    r_issn = v.eissn.replace('-', '');
			                }
			                var r_year = v.date.substr(0, 4);
			                if (r_issn.length > 0 && r_year.length == 4) {
			                    rta_query_length++;
			                    rta_query["record[" + r_id + "]"] = r_issn + "|" + r_year;
			                }
			            }
			        });
			        if (rta_query_length > 0) {
			            $.each($('.EXLResultAvailability em'),
			            function(i, d) {
			                var record_id = $(d).parents('.EXLResult').find(".EXLResultRecordId").attr('id');
			                if (record_id.substring(0, 2) == 'TN') {
			                    $(d).append('<span style="color:black;font-weight:normal;" class="LBSUpdating">(Updating...)</span>');
			                }
			            });

						var server_url = jQuery.limo.primo_central.rta.url;

			            $.ajax({
			                type: "GET",
			                async: false,
			                cache: false,
			                dataType: 'jsonp',
			                data: rta_query,
			                url: server_url,
			                success: function(data, status, xhr) {
			                    $.each($('.EXLResultAvailability em'),
			                    function(i, d) {
			                        $('.LBSUpdating').remove();
			                        var record_id = $(d).parents('.EXLResult').find(".EXLResultRecordId").attr('id');
			                        if (record_id.substring(0, 2) == 'TN') {
			                            var record = data[record_id];
			                            if (record && record.services == 'getFullTxt') {
			                                $(d).replaceWith('<em class="EXLResultStatusAvailable">Full text available on campus.</em>');
			                            }
			                            else {
			                                var availability = $(d).text().replace(/\s{2,}/g, '');
			                                if (record && record.issn.length > 0) {
			                                    $(d).replaceWith('<em class="EXLResultStatusNotAvailable">No full-text.</em>');
			                                }
			                            }
			                        }
			                    });
			                },
			                error: function(xhr, status, error) {
			                    $('.LBSUpdating').remove();
			                    alert("Error calling Limo Web Services.");
			                },
			                complete: function() {
			                    $('.LBSUpdating').remove();
			                },
			                timeout: 3000
			            });
					}					
				}
			}
        }
	}
})(jQuery);



