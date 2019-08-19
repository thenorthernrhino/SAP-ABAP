*&---------------------------------------------------------------------*
*& Report  ZABAP_REP_ALV
*&
*&---------------------------------------------------------------------*
*& Author: Ankit Kumar <mail2ankit85@gmail.com>
*& Description: ABAP Report Program to capture BAPI Success/Error Msg 
*& into ALV. "ZTEST00000000000100.
*&---------------------------------------------------------------------*

REPORT ZABAP_REP_ALV.

TYPE-POOLS: slis, abap.

TABLES: bapi_bus2002_act_new, bapiret2, bapiparex.

TYPES: BEGIN OF msg_str,
        status(4) TYPE c,
        network TYPE  bapi_network_list-network,
        type    TYPE  bapi_mtype,
        message TYPE  bapi_msg,
       END OF msg_str.

TYPES: BEGIN OF record,
          i_number  TYPE nw_aufnr,
          activity   TYPE cn_vornr,
          control_key	 TYPE steus,
          plant	 TYPE werks_d,
          description	TYPE ltxa1,
          wbs_element	TYPE ps_posid,
          work_activity	TYPE arbeit,
          un_work   TYPE arbeite,
          info_rec  TYPE infnr,
          purch_org  TYPE ekorg,
          pur_group  TYPE ekgrp,
          matl_group  TYPE matkl,
          price	TYPE preis,
          currency  TYPE waers,
          cost_elem	TYPE kstar,
          operation_qty	TYPE cx_losvg,
          operation_measure_unit TYPE vorme,
          preq_name TYPE afnam,
       END OF record.

DATA: t_upload TYPE STANDARD TABLE OF record.
DATA: w_upload TYPE record.

DATA: t_msg TYPE STANDARD TABLE OF msg_str.
DATA: w_msg TYPE msg_str.

DATA: it_raw TYPE truxs_t_text_data.
DATA: t_line TYPE STANDARD TABLE OF tline.
DATA: w_line TYPE tline.

*********************** BAPI CALL
DATA: i_number     TYPE bapi_network_list-network,
      it_activity	 TYPE	STANDARD TABLE OF bapi_bus2002_act_new,
      wa_activity	 TYPE	bapi_bus2002_act_new,
      et_return	   TYPE	STANDARD TABLE OF bapiret2,
      wa_return    TYPE bapiret2,
      extensionin  TYPE	STANDARD TABLE OF bapiparex,
      extensionout TYPE	STANDARD TABLE OF bapiparex,
      et_return1   TYPE STANDARD TABLE OF bapiret2,
      wait         TYPE bapita-wait,
      return       TYPE bapiret2.

***************************************
*********  ALV Grid Variables
***************************************
DATA: wa_fieldcat  TYPE slis_fieldcat_alv.
DATA: gd_layout    TYPE slis_layout_alv.
DATA: gt_list_top_of_page TYPE slis_t_listheader.
DATA: it_fieldcat  TYPE slis_t_fieldcat_alv.
DATA: it_filter    TYPE  slis_t_filter_alv.
DATA: g_save TYPE c.
DATA: g_exit TYPE c.
DATA: g_variant LIKE disvariant.
DATA: gx_variant LIKE disvariant.
DATA: gv_repid TYPE  sy-repid.
DATA: wa_exclude TYPE slis_extab.
DATA: it_exclude TYPE slis_t_extab.
DATA: col_pos TYPE i.

SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
SELECTION-SCREEN SKIP 1.
PARAMETERS: p_file TYPE localfile.
SELECTION-SCREEN: END OF BLOCK b1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  CALL FUNCTION 'F4_FILENAME'
    EXPORTING
      field_name = 'P_FILE'
    IMPORTING
      file_name  = p_file.

*********Start of Selection************
START-OF-SELECTION.
    PERFORM data_upload.
END-OF-SELECTION.
    PERFORM call_transaction_rec.
    PERFORM display_report.

*&---------------------------------------------------------------------*
*&      Form  CALL_TRANSACTION_REC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM call_transaction_rec .
  CLEAR: w_upload.
  LOOP AT t_upload INTO w_upload.
         REFRESH it_activity.
         CLEAR i_number.
         i_number =  w_upload-i_number.
         wa_activity-activity = w_upload-activity.
         wa_activity-control_key     = w_upload-control_key.
         wa_activity-plant           = w_upload-plant.
         wa_activity-description     = w_upload-description.
         wa_activity-wbs_element     = w_upload-wbs_element.
         wa_activity-work_activity   = w_upload-work_activity.
         wa_activity-un_work         = w_upload-un_work.
         wa_activity-info_rec   = w_upload-info_rec.
         wa_activity-purch_org  = w_upload-purch_org.
         wa_activity-pur_group  = w_upload-pur_group.
         wa_activity-matl_group = w_upload-matl_group.
         wa_activity-price      = w_upload-price.
         wa_activity-currency   = w_upload-currency.
         wa_activity-cost_elem  = w_upload-cost_elem.
         wa_activity-operation_qty = w_upload-operation_qty.
         wa_activity-operation_measure_unit = w_upload-operation_measure_unit.
         wa_activity-preq_name = w_upload-preq_name.

         APPEND wa_activity TO  it_activity.

    CALL FUNCTION 'BAPI_PS_INITIALIZATION'.

    CALL FUNCTION 'BAPI_BUS2002_ACT_CREATE_MULTI'
      EXPORTING
        i_number           = i_number
      TABLES
        it_activity        = it_activity
        et_return          = et_return
        extensionin        = extensionin
        extensionout       = extensionout
              .

    IF et_return IS NOT INITIAL.
      LOOP AT et_return INTO wa_return.
        IF wa_return-type = 'S'.
          w_msg-status  = '@08@'.
        ELSEIF wa_return-type = 'I'.
          w_msg-status  = '@09@'.
        ELSE.
          w_msg-status  = '@0A@'.
        ENDIF.
        w_msg-network = w_upload-i_number.
        w_msg-type    = wa_return-type.
        w_msg-message = wa_return-message.

        IF w_msg-type = 'S'.
          CALL FUNCTION 'BAPI_PS_PRECOMMIT'
           TABLES
             et_return       = et_return1
                    .

          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
           EXPORTING
             wait          = wait
           IMPORTING
             return        = return
                    .
        ENDIF.

        APPEND w_msg TO t_msg.
        CLEAR w_msg.
      ENDLOOP.
    ENDIF.

    CLEAR: w_upload.
    CLEAR: wa_activity.
  ENDLOOP.
ENDFORM.                    " CALL_TRANSACTION_REC
*&---------------------------------------------------------------------*
*&      Form  DATA_UPLOAD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM data_upload .

  REFRESH: t_upload.

  CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
    EXPORTING
      i_field_seperator    = 'X'
      i_line_header        = 'X'
      i_tab_raw_data       = it_raw
      i_filename           = p_file
    TABLES
      i_tab_converted_data = t_upload
    EXCEPTIONS
      conversion_failed    = 1
      OTHERS               = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " DATA_UPLOAD
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_REPORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_report .
  PERFORM build_layout.
  PERFORM build_fieldcat.
  PERFORM display_list.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  BUILD_LAYOUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_layout .
 REFRESH it_fieldcat.
 PERFORM insert_fieldcat USING:
*************************************************************************************************************************************
* Employee Details
*************************************************************************************************************************************
        'STATUS'      'Status' space              space   space   space   space   12  space,
        'NETWORK'     space   'BAPI_NETWORK_LIST' 'NETWORK'   space   space   space   12  space,
        'TYPE'        space   'BAPIRET2' 'TYPE'               space   space   space   12  space,
        'MESSAGE'     space   'BAPIRET2' 'MESSAGE'            space   space   space   30  space.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_fieldcat .
  gd_layout-no_input          = 'X'.
  gd_layout-colwidth_optimize = 'X'.
  gd_layout-no_min_linesize   = 'X'.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_list .
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
         EXPORTING
*   I_INTERFACE_CHECK                 = ' '
*   I_BYPASSING_BUFFER                = ' '
*   I_BUFFER_ACTIVE                   = ' '
      i_callback_program                = gv_repid
*   I_CALLBACK_PF_STATUS_SET          = ' '
*   I_CALLBACK_USER_COMMAND           = ' '
*   I_CALLBACK_TOP_OF_PAGE            = ' '
*   I_CALLBACK_HTML_TOP_OF_PAGE       = ' '
*   I_CALLBACK_HTML_END_OF_LIST       = ' '
*   I_STRUCTURE_NAME                  =
*   I_BACKGROUND_ID                   = ' '
*   I_GRID_TITLE                      =
*   I_GRID_SETTINGS                   =
      is_layout                         = gd_layout
      it_fieldcat                       = it_fieldcat
      it_excluding                      = it_exclude
*   IT_SPECIAL_GROUPS                 =
*   IT_SORT                           =
      it_filter                         = it_filter
*   IS_SEL_HIDE                       =
      i_default                         = 'X'
      i_save                            = 'A'
      is_variant                        = g_variant
*   it_events                         =
*   IT_EVENT_EXIT                     =
*   IS_PRINT                          =
*   is_reprep_id                      =
*   I_SCREEN_START_COLUMN             = 0
*   I_SCREEN_START_LINE               = 0
*   I_SCREEN_END_COLUMN               = 0
*   I_SCREEN_END_LINE                 = 0
*   IT_ALV_GRAPHICS                   =
*   IT_HYPERLINK                      =
*   IT_ADD_FIELDCAT                   =
*   IT_EXCEPT_QINFO                   =
*   I_HTML_HEIGHT_TOP                 =
*   I_HTML_HEIGHT_END                 =

* IMPORTING
*   E_EXIT_CAUSED_BY_CALLER           =
*   ES_EXIT_CAUSED_BY_USER            =
          TABLES
            t_outtab                          = t_msg
         EXCEPTIONS
           program_error                     = 1
           OTHERS                            = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  INSERT_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0468   text
*      -->P_SPACE  text
*      -->P_0470   text
*      -->P_0471   text
*      -->P_SPACE  text
*      -->P_SPACE  text
*      -->P_SPACE  text
*      -->P_12     text
*      -->P_SPACE  text
*----------------------------------------------------------------------*
FORM insert_fieldcat  USING    VALUE(p_field)
                               VALUE(p_fname)
                               p_rtab
                               p_rfield
                               p_hotp
                               p_no_out
                               p_icon
                               p_oplen
                               emphasize.

  ADD 1 TO col_pos.
  wa_fieldcat-col_pos       = col_pos.
  wa_fieldcat-fieldname     = p_field.
  wa_fieldcat-seltext_l     = p_fname.
  wa_fieldcat-ref_fieldname = p_rfield.
  wa_fieldcat-ref_tabname   = p_rtab.
  wa_fieldcat-hotspot       = p_hotp.
  wa_fieldcat-no_out        = p_no_out.
  wa_fieldcat-icon          = p_icon.
  wa_fieldcat-outputlen     = p_oplen.
  wa_fieldcat-emphasize     = emphasize.
  APPEND wa_fieldcat TO it_fieldcat.
  CLEAR  wa_fieldcat.
ENDFORM.