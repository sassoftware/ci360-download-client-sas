/*-----------------------------------------------------------------------------
 Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
 SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_src_file_reader (file_var=,extTableNm=);

	%let infile_options= %str(infile &file_var dlm = '01'x dsd &DSC_FILE_READ_OPTION);

	%if &extTableNm = COMPLETED_SESSION_DETAILS %then 
	%do;
		length browser_nm	$ 52
			browser_version_no	$ 16
			country_nm			$ 85
			country_cd			$ 2
			state_region_cd		$ 2
			region_nm			$ 256
			city_nm				$ 390
			latitude			$ 13
			longitude			$ 13
			ip_address			$ 64
			organization_nm		$  256	
			postal_cd			$ 13 
			metro_cd			 $ 30
			device_nm			$ 85
			platform_desc		$ 78
			platform_type_nm	$ 52 
			profile_nm1			$ 169
			profile_nm2			$ 169
			profile_nm3			$ 169
			profile_nm4			$ 169
			profile_nm5			$ 169 
			session_id			$ 29
			session_dt			$ 20	
			session_start_dttm	$ 30
			client_session_start_dttm	$ 30
			previous_session_id		$ 29
			flash_version_no	$ 16
			flash_enabled_flg	$ 1	
			java_version_no		$ 12
			java_enabled_flg	$ 1
			java_script_enabled_flg	$ 1
			cookies_enabled_flg 	$ 1
			user_language_cd	$ 12
			screen_color_depth_no	$ 10 
			screen_size_txt		$ 12
			user_agent_nm		$ 512
			new_visitor_flg		$ 2
			session_timeout $ 10
			visitor_id			$ 32
			identity_id			$ 36
			seconds_spent_in_session_cnt 	$ 20
			last_session_activity_dttm 	$ 30
			active_sec_spent_in_sessn_cnt 	$ 30 
			user_data_volume_bytes_cnt 	$ 30
			user_data_trans_sec_cnt 	$ 30
			network_data_volume_bytes_cnt   $ 30
			netwrk_data_trans_sec_cnt       $ 30
			last_user_id 		$ 128
			load_dttm $ 30;
		&infile_options ;
		input 	
			browser_nm	$ 
			browser_version_no	$ 
			country_nm			$ 
			country_cd			$ 
			state_region_cd		$ 
			region_nm			$ 
			city_nm				$ 
			latitude			$ 
			longitude			$ 
			ip_address			$ 
			organization_nm		$ 
			postal_cd			$ 
			metro_cd			 $
			device_nm			$ 
			platform_desc		$ 
			platform_type_nm	$ 
			profile_nm1			$ 
			profile_nm2			$ 
			profile_nm3			$ 
			profile_nm4			$ 
			profile_nm5			$ 
			session_id			$ 
			session_dt			$ 
			session_start_dttm	$ 
			client_session_start_dttm	$ 
			previous_session_id		$ 
			flash_version_no	$ 
			flash_enabled_flg	$ 	
			java_version_no		$ 
			java_enabled_flg	$ 
			java_script_enabled_flg	$ 
			cookies_enabled_flg 	$ 
			user_language_cd	$ 
			screen_color_depth_no	$ 
			screen_size_txt		$ 
			user_agent_nm		$ 
			new_visitor_flg		$ 
			session_timeout $ 
			visitor_id			$ 
			identity_id			$ 
			seconds_spent_in_session_cnt 	$ 
			last_session_activity_dttm 	$ 
			active_sec_spent_in_sessn_cnt 	$ 
			user_data_volume_bytes_cnt 	$ 
			user_data_trans_sec_cnt 	$ 
			network_data_volume_bytes_cnt   $ 
			netwrk_data_trans_sec_cnt       $ 
			last_user_id 		$ 
			load_dttm $ ;
	%end;
	%else %if &extTableNm = VISIT_DETAILS %then 
	%do;
		length visit_id 		$ 32
			port_no				$ 10
			origination_nm		$ 260
			origination_type_nm $ 65
			origination_placement_nm 	$ 390
			origination_creative_nm 	$ 260
			origination_tracking_cd 	$ 65
			referrer_domain_nm 		$ 215
			referrer_txt  			$ 1332
			search_engine_domain_txt 	$ 215
			search_engine_desc 		$ 130
			search_term_txt 		$ 1332
			session_id 			$ 29
			visit_dttm 			$ 30
			subject1_id_val 	$ 32
			subject2_id_val 	$ 32
			subject3_id_val 	$ 32
			subject4_id_val 	$ 32
			subject5_id_val 	$ 32
			sequence_no 		$ 10
			response_tracking_cd 		$ 14
			referrer_query_string_txt	$ 1332
			identity_id $ 36
			load_dttm $ 20;
		&infile_options ;
		input
			visit_id 		$ 
			port_no				$ 
			origination_nm		$ 
			origination_type_nm $ 
			origination_placement_nm 	$ 
			origination_creative_nm 	$ 
			origination_tracking_cd 	$ 
			referrer_domain_nm 		$ 
			referrer_txt  			$ 
			search_engine_domain_txt 	$ 
			search_engine_desc 		$ 
			search_term_txt 		$ 
			session_id 			$ 
			visit_dttm 			$ 
			subject1_id_val 	$ 
			subject2_id_val 	$ 
			subject3_id_val 	$ 
			subject4_id_val 	$ 
			subject5_id_val 	$ 
			sequence_no 		$ 
			response_tracking_cd 		$ 
			referrer_query_string_txt	$ 
			identity_id $ 
			load_dttm $ ;
	%end;
	%else %if &extTableNm = PAGE_DETAILS %then 
	%do;
		length detail_id		$ 29
			session_id		$29
			visit_id		$32
			session_dt		$ 20
			detail_dttm		$ 30
			bytes_sent_cnt	$ 20
			page_load_sec_cnt	$ 20
			page_complete_sec_cnt	$ 20
			window_size_txt		$ 20
			user_id			$ 128
			domain_nm		$ 165
			protocol_nm		$ 8
			class1_id		$ 650
			class2_id		$ 650
			class3_id		$ 650
			class4_id		$ 650
			class5_id		$ 650
			class6_id		$ 650
			class7_id		$ 650
			class8_id		$ 650
			class9_id		$ 650
			class10_id		$ 650
			class11_id		$ 650
			class12_id		$ 650
			class13_id		$ 650
			class14_id		$ 650
			class15_id		$ 650
			page_url_txt		$ 1332
			page_desc		$ 1332
			url_domain		$ 215
			identity_id $ 36
			load_dttm	$ 30;
		&infile_options ;
		input
		detail_id		$ 
			session_id		$
			visit_id		$
			session_dt		$
			detail_dttm		$
			bytes_sent_cnt	$
			page_load_sec_cnt	$ 
			page_complete_sec_cnt	$ 
			window_size_txt		$ 
			user_id			$ 
			domain_nm		$ 
			protocol_nm		$ 
			class1_id		$ 
			class2_id		$ 
			class3_id		$ 
			class4_id		$ 
			class5_id		$ 
			class6_id		$ 
			class7_id		$ 
			class8_id		$ 
			class9_id		$ 
			class10_id		$ 
			class11_id		$ 
			class12_id		$ 
			class13_id		$ 
			class14_id		$ 
			class15_id		$ 
			page_url_txt		$ 
			page_desc		$ 
			url_domain		$ 
			identity_id $
			load_dttm	$;
	%end;
	%else %if &extTableNm = CUSTOM_ATTRIBUTES %then 
	%do;
		length 	attrib_nm  $ 32
    		attrib_val $ 650
    		attrib_dttm $ 30
    		detail_id $ 32
    		visit_id $ 32
    		session_id $ 29
			identity_id $ 36
    		load_dttm $ 30;
		&infile_options ;
		input 
    		attrib_val $ 
    		attrib_dttm $
    		detail_id $ 
    		visit_id $ 
			session_id $ 
			identity_id $
    		load_dttm $ ;
	%end;
	%else %if &extTableNm = GOAL_DETAILS %then 
	%do;
		length  goal_nm  $ 260
    		goal_group_nm $ 130
    		goal_revenue_amt $ 30
    		goal_reached_dttm $ 30
    		detail_id   $ 32
    		visit_id    $ 32
    		session_id  $ 29
    		identity_id $ 36
    		load_dttm $ 30;
		&infile_options ;
		input goal_nm  $ 
    		goal_group_nm $ 
    		goal_revenue_amt $ 
    		goal_reached_dttm $
    		detail_id   $ 
    		visit_id    $ 
    		session_id  $ 
    		identity_id $ 
    		load_dttm $ ;
	%end;
	%else %if &extTableNm = PRODUCT_DETAILS %then 
	%do;
		length product_nm  $ 130
    		product_group_nm $ 130
    		product_id $ 130
    		product_sku $ 100
    		currency_cd $ 6
    		price_val $ 30
    		action_dttm $ 30
    		availability_message_txt $ 650
    		saving_message_txt $ 650
    		shipping_message_txt $ 650
    		detail_id   $ 32
    		visit_id    $ 32
    		session_id  $ 29
    		identity_id $ 36
    		load_dttm $ 30;
		&infile_options ;
		input product_nm  $ 
    		product_group_nm $ 
    		product_id $ 
    		product_sku $ 
    		currency_cd $ 
    		price_val $ 
    		action_dttm $ 
    		availability_message_txt $ 
    		saving_message_txt $ 
    		shipping_message_txt $ 
    		detail_id   $ 
    		visit_id    $ 
    		session_id  $ 
    		identity_id $ 
    		load_dttm $ ;
	%end;
	%else %if &extTableNm = PROMOTION_DETAILS %then 
	%do;
		length 
			promotion_nm  $ 260
    		promotion_tracking_cd $ 65
    		promotion_type_nm $ 65
    		promotion_placement_nm $ 260
    		promotion_creative_nm $ 260
    		promotion_number $ 10
			record_type $ 10
    		click_dttm $ 30
    		display_dttm $ 30
    		derived_display_flg $ 1
    		response_tracking_cd $ 14
    		treatment_tracking_cd $ 32
    		subject1_id_val $ 32
    		subject2_id_val $ 32
    		subject3_id_val $ 32
    		subject4_id_val $ 32
    		subject5_id_val $ 32
    		detail_id   $ 32
    		visit_id    $ 32
    		session_id  $ 29
    		identity_id $ 36
    		load_dttm $ 30;
		&infile_options ;
		input
			promotion_nm  $ 
    		promotion_tracking_cd $ 
    		promotion_type_nm $ 
    		promotion_placement_nm $ 
    		promotion_creative_nm $ 
    		promotion_number $ 
			record_type $ 
    		click_dttm $
    		display_dttm $ 
    		derived_display_flg $
    		response_tracking_cd $ 
    		treatment_tracking_cd $ 
    		subject1_id_val $ 
    		subject2_id_val $ 
    		subject3_id_val $ 
    		subject4_id_val $ 
    		subject5_id_val $ 
    		detail_id   $ 
    		visit_id    $ 
    		session_id  $ 
    		identity_id $ 
    		load_dttm $ ;
	%end;
	%else %if &extTableNm = DOCUMENT_DETAILS %then
	%do;
		length uri_txt  $ 1332
    		alt_txt  $ 1332
    		link_id  $ 1332
    		link_name  $ 1332
    		link_selector_path  $ 1332
    		link_event_dttm $ 30
    		detail_id   $ 32
    		visit_id    $ 32
    		session_id  $ 29
    		identity_id $ 36
    		load_dttm $ 30;
		&infile_options ;
		input 	uri_txt  $ 
    		alt_txt  $ 
    		link_id  $ 
    		link_name  $ 
    		link_selector_path  $ 
    		link_event_dttm $ 
    		detail_id   $ 
    		visit_id    $ 
    		session_id  $ 
    		identity_id $ 
    		load_dttm $ ;
	%end;
	%else %if &extTableNm = SEARCH_RESULTS %then
	%do;
		length search_nm $ 42
    		search_results_dttm  $ 30
    		results_displayed_flg $ 1
    		search_results_displayed $ 10
    		detail_id   $ 32
    		visit_id    $ 32
    		session_id  $ 29
    		identity_id $ 36
    		load_dttm $ 30;
		&infile_options ;
		input search_nm $ 
    		search_results_dttm  $ 
    		results_displayed_flg $
    		search_results_displayed $ 
    		detail_id   $ 
    		visit_id    $ 
    		session_id  $ 
    		identity_id $ 
    		load_dttm $ ;
	%end;
	%else %if &extTableNm = FORM_DETAILS %then
	%do;
		length form_nm $ 65
    		form_field_nm $ 325
    		form_field_id $ 325
    		form_field_detail_dttm $ 30
    		form_field_value $ 2600
    		attempt_index_cnt $ 10
    		attempt_status_cd $ 42
    		change_index_no   $ 10
    		submit_flg $ 1
    		is_search_flg $ 1
    		detail_id   $ 32
    		visit_id    $ 32
    		session_id  $ 29
    		identity_id $ 36
    		load_dttm $ 30;
		&infile_options ;
		input form_nm $ 
    		form_field_nm $ 
    		form_field_id $ 
    		form_field_detail_dttm $ 
    		form_field_value $ 
    		attempt_index_cnt $ 
    		attempt_status_cd $ 
    		change_index_no   $ 
    		submit_flg $ 
    		is_search_flg $ 
    		detail_id   $ 
    		visit_id    $ 
    		session_id  $ 
    		identity_id $ 
    		load_dttm $ ;
	%end;
	%else %if &extTableNm = PAGE_ERRORS %then 
	%do;
		length 	in_page_error_txt $ 260 
		    error_location_txt $ 21
		    in_page_error_dttm $50
		    detail_id   $ 32
		    visit_id    $ 32
		    session_id  $ 29
		    identity_id $ 36
		    load_dttm $ 40;
		&infile_options ;
		input  in_page_error_txt $
		    error_location_txt $
		    in_page_error_dttm $
		    detail_id   $ 
		    visit_id    $ 
			session_id  $
		    identity_id $
		    load_dttm $  ;
	%end;
	%else %if &extTableNm = ORDER_SUMMARY %then 
	%do;
		length activity_dttm        $ 30
    		cart_id              $ 42
    		checkout_flg         $ 1
    		currency_cd          $ 6
    		delivery_type_desc   $ 42
    		order_id             $ 42
    		payment_type_desc    $ 42
    		purchase_flg         $ 1
    		shipping_amt         $ 20
    		total_price_amt      $ 20
    		total_tax_amt        $ 20
    		shipping_country_nm $ 85
    		shipping_state_region_cd $ 2
    		shipping_city_nm $ 390
    		shipping_postal_cd $ 10
    		billing_country_nm $ 85
    		billing_state_region_cd $ 2
    		billing_city_nm $ 390
    		billing_postal_cd $ 10
    		detail_id   $ 32
    		visit_id    $ 32
    		session_id  $ 29
    		identity_id $ 36
    		load_dttm $ 30;
		&infile_options ;
		input activity_dttm        $ 
    		cart_id              $ 
    		checkout_flg         $ 
    		currency_cd          $ 
    		delivery_type_desc   $ 
    		order_id             $ 
    		payment_type_desc    $ 
    		purchase_flg         $ 
			shipping_amt         $ 
    		total_price_amt      $ 
    		total_tax_amt        $ 
    		shipping_country_nm $ 
    		shipping_state_region_cd $ 
    		shipping_city_nm $ 
    		shipping_postal_cd $
    		billing_country_nm $
    		billing_state_region_cd $ 
    		billing_city_nm $ 
    		billing_postal_cd $ 
    		detail_id   $ 
    		visit_id    $ 
    		session_id  $ 
    		identity_id $ 
    		load_dttm $ ;
	%end;
	%else %if &extTableNm = CART_ACTIVITY_DETAILS %then 
	%do;
		length  product_nm  $ 130
			product_group_nm $ 130
    		product_id $ 130
    		product_sku $ 100
    		currency_cd $ 6
    		activity_cd $ 20    
    		activity_dttm $ 30
    		cart_id $ 42
    		displayed_cart_items_no $ 10
    		displayed_cart_amt   $ 20
    		quantity_val $ 10
    		unit_price_amt  $ 20
    		detail_id   $ 32
    		visit_id    $ 32
    		session_id  $ 29
    		identity_id $ 36
    		load_dttm $ 30;
		&infile_options ;
		input product_nm  $ 
			product_group_nm $ 
    		product_id $ 
    		product_sku $ 
    		currency_cd $ 
    		activity_cd $     
    		activity_dttm $ 
    		cart_id $ 
    		displayed_cart_items_no $ 
    		displayed_cart_amt   $ 
    		quantity_val $ 
    		unit_price_amt  $ 
    		detail_id   $ 
    		visit_id    $ 
    		session_id  $ 
    		identity_id $ 
    		load_dttm $ ;
	%end;
	%else %if &extTableNm = BUSINESS_PROCESS_STEP_DETAILS %then 
	%do;
		length process_nm           $ 130
    		process_step_nm      $ 130
    		step_order_no        $ 10
    		process_instance_no  $ 10
    		process_dttm         $ 30
    		process_attempt_cnt  $ 10
    		attribute1_txt       $ 130
    		attribute2_txt       $ 130
    		is_completion_flg    $ 1
    		is_start_flg         $ 1
    		process_exception_txt $ 1300
    		process_exception_dttm $ 30 
    		next_detail_id   $ 32
    		detail_id   $ 32
    		visit_id    $ 32
    		session_id  $ 29
    		identity_id $ 36
    		load_dttm $ 30;
		&infile_options ;
		input process_nm           $ 
    		process_step_nm      $ 
    		step_order_no        $ 
    		process_instance_no  $ 
    		process_dttm         $ 
    		process_attempt_cnt  $ 
    		attribute1_txt       $ 
    		attribute2_txt       $ 
    		is_completion_flg    $ 
    		is_start_flg         $ 
    		process_exception_txt $ 
    		process_exception_dttm $ 
    		next_detail_id   $ 
    		detail_id   $ 
    		visit_id    $ 
    		session_id  $ 
    		identity_id $ 
    		load_dttm $ ;
	%end;
	%else %if &extTableNm = COMPLTE_MEDIA_DETAILS %then 
	%do;
		length media_nm $ 260
    		media_uri_txt $ 2024
    		media_player_nm $ 30
    		media_player_version_txt $ 20
    		start_tm $ 20
    		end_tm  $ 20
    		play_start_dttm $ 30
    		play_end_dttm $ 30
    		media_duration_secs  $ 20
    		max_play_secs   $ 20
    		media_display_duration_secs $ 20
    		view_duration_secs  $ 20
    		exit_point_secs $ 20
    		interaction_cnt $ 10
    		detail_id $ 32
    		visit_id  $ 32
    		session_id $ 29
    		identity_id $ 36
    		load_dttm $ 30;
		&infile_options ;
		input media_nm $ 
    		media_uri_txt $ 
    		media_player_nm $ 
    		media_player_version_txt $ 
    		start_tm $ 
    		end_tm  $ 
    		play_start_dttm $ 
    		play_end_dttm $ 
    		media_duration_secs  $ 
    		max_play_secs   $ 
    		media_display_duration_secs $ 
    		view_duration_secs  $ 
    		exit_point_secs $ 
    		interaction_cnt $ 
    		detail_id $ 
    		visit_id  $ 
    		session_id $
    		identity_id $ 
    		load_dttm $ ;
	%end;
	%else %if &extTableNm = INCOMPLTE_MEDIA_DETAILS %then 
	%do;
		length media_nm $ 260
    		media_uri_txt $ 2024
    		media_player_nm $ 30
    		media_player_version_txt $ 20
    		play_start_dttm $ 30
    		media_duration_secs  $ 20
    		detail_id $ 32
    		visit_id  $ 32
    		session_id $ 29
    		identity_id $ 36
    		load_dttm $ 30 ;
		&infile_options ;
		input media_nm $ 
    		media_uri_txt $ 
    		media_player_nm $
    		media_player_version_txt $ 
    		play_start_dttm $ 
    		media_duration_secs  $ 
    		detail_id $ 
    		visit_id  $ 
    		session_id $
    		identity_id $
    		load_dttm $ ;
	%end;
%mend;

  
