CLASS zcl_breadmatconprep DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_breadmatconprep IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    DATA(lv_top)   =   io_request->get_paging( )->get_page_size( ).
    DATA(lv_skip)  =   io_request->get_paging( )->get_offset( ).
    DATA(lv_max_rows) = COND #( WHEN lv_top = if_rap_query_paging=>page_size_unlimited THEN 0 ELSE lv_top ).

    DATA(lt_parameters)  = io_request->get_parameters( ).
    DATA(lt_fileds)  = io_request->get_requested_elements( ).
    DATA(lt_sort)  = io_request->get_sort_elements( ).

    TRY.
        DATA(lt_Filter_cond) = io_request->get_filter( )->get_as_ranges( ).
      CATCH cx_rap_query_filter_no_range INTO DATA(lx_no_sel_option).
        CLEAR lt_Filter_cond.
    ENDTRY.

    LOOP AT lt_filter_cond INTO DATA(ls_filter_cond).
      IF ls_filter_cond-name =  'PLANT'.
        DATA(lt_werks) = ls_filter_cond-range[].
      ELSEIF ls_filter_cond-name = 'MATERIAL'.
        DATA(lt_matnr) = ls_filter_cond-range[].
      ELSEIF ls_filter_cond-name = 'RANGEDATE'.
        DATA(lt_date) = ls_filter_cond-range[].
      ELSEIF ls_filter_cond-name = 'TODATE'.
        DATA(lt_todate) = ls_filter_cond-range[].
      ELSEIF ls_filter_cond-name = 'SHIFT'.
        DATA(lt_shift) = ls_filter_cond-range[].
      ENDIF.
    ENDLOOP.


    DATA: lt_response    TYPE TABLE OF zc_repmatbread,
          ls_line        TYPE zc_repmatbread,
          lt_responseout TYPE TABLE OF zc_repmatbread,
          ls_responseout TYPE zc_repmatbread.

    DATA lv_matnr TYPE c LENGTH 18.

    TYPES: BEGIN OF ty_sum,
             plant           TYPE c LENGTH 4,
             rangedate       TYPE datn,
             todate          TYPE datn,
             material        TYPE c LENGTH 40,
             matDesc         TYPE c LENGTH 40,
             um              TYPE c LENGTH 3,
             ShiftDefinition TYPE c LENGTH 4,
             qty             TYPE I_MaterialDocumentItem_2-QuantityInEntryUnit,
           END OF ty_sum.
    DATA: it_qty TYPE TABLE OF ty_sum,
          wa_qty TYPE ty_sum.

    LOOP AT lt_matnr INTO DATA(ls_aufnr).
      lv_matnr = |{ ls_aufnr-low ALPHA = IN }|.
      ls_aufnr-low = lv_matnr.
      CLEAR lv_matnr.
      lv_matnr = |{ ls_aufnr-high ALPHA = IN }|.
      ls_aufnr-high = lv_matnr.
      MODIFY lt_matnr FROM ls_aufnr.
      CLEAR : ls_aufnr, lv_matnr.
    ENDLOOP.

    READ TABLE lt_date INTO DATA(wa_fromdate) INDEX 1.
    READ TABLE lt_todate INTO DATA(wa_todate) INDEX 1.
    READ TABLE lt_werks INTO DATA(wa_werks) INDEX 1.

    SELECT SINGLE FROM zrepmatbread
    FIELDS plant, material, rangedate, todate
    WHERE todate >= @wa_fromdate-low AND rangedate <= @wa_fromdate-low
    AND plant = @wa_werks-low
    INTO @DATA(wa_zrepmatbread) PRIVILEGED ACCESS.

    SELECT SINGLE FROM zrepmatbread
    FIELDS plant, material, rangedate, todate
    WHERE todate <= @wa_todate-low AND rangedate >= @wa_todate-low
    AND plant = @wa_werks-low
    INTO @DATA(wa_zrepmatbread2) PRIVILEGED ACCESS.

    IF wa_todate-low+0(4) = wa_fromdate-low+0(4) AND wa_todate-low+4(2) = wa_fromdate-low+4(2)
    AND wa_zrepmatbread IS INITIAL AND wa_zrepmatbread2 IS INITIAL.

      SELECT FROM I_ProductionOrder AS a
      INNER JOIN I_mfgorderconfirmation AS c ON a~ProductionOrder = c~ManufacturingOrder
      LEFT JOIN I_MaterialDocumentItem_2 AS d ON c~MaterialDocument = d~MaterialDocument AND c~MaterialDocumentYear = d~MaterialDocumentYear
      LEFT JOIN I_ProductText AS b ON d~Material = b~Product AND b~Language = 'E'
      FIELDS  d~Material, d~Plant, d~MaterialBaseUnit,
      b~ProductName, c~ShiftDefinition, d~GoodsMovementType,
             SUM(
             case when d~GoodsMovementType = '261' THEN d~QuantityInEntryUnit
                  else d~QuantityInEntryUnit * -1 end
              ) AS QuantityInEntryUnit
*      a~ProductionOrder, d~MaterialDocument, d~MaterialDocumentYear, d~ReversedMaterialDocument,
*                d~Material, d~Plant, d~StorageLocation, d~QuantityInEntryUnit, d~PostingDate, d~GoodsMovementType,
*            d~MaterialBaseUnit, d~Batch, b~ProductName, c~ShiftDefinition, a~CreationDate,a~CompanyCode,
*            c~ConfirmationScrapQuantity, c~ConfirmationReworkQuantity,c~ConfirmationYieldQuantity,c~WorkCenterInternalID

      WHERE d~GoodsMovementType IN ( '261', '262' )
      AND d~Plant IN @lt_werks AND d~Material IN @lt_matnr
      AND a~CreationDate >= @wa_fromdate-low AND a~CreationDate <= @wa_todate-low
      AND d~Material IS NOT INITIAL AND c~ShiftDefinition IN @lt_shift
      GROUP BY d~Material, d~Plant,
*      d~Batch,d~StorageLocation,d~PostingDate,
      d~MaterialBaseUnit, b~ProductName, c~ShiftDefinition, d~GoodsMovementType
    INTO TABLE @DATA(lt_final) PRIVILEGED ACCESS.

      SORT lt_final BY Plant Material ShiftDefinition.

      LOOP AT lt_final INTO DATA(wa_qty1).

        ls_line-material     = wa_qty1-material.
        ls_line-plant        = wa_qty1-plant.
        ls_line-matdesc      = wa_qty1-ProductName.
        ls_line-rangedate    = wa_fromdate-low.
        ls_line-todate       = wa_todate-low.

        IF wa_qty1-shiftdefinition = '1'.
            ls_line-shift = 'DAY'.
        ELSEIF wa_qty1-shiftdefinition = '2'.
            ls_line-shift = 'NIGHT'.
        ENDIF.
        ls_line-shift        = wa_qty1-shiftdefinition.
        ls_line-um           = wa_qty1-MaterialBaseUnit.
        ls_line-quantity     = wa_qty1-quantityinentryunit.

        APPEND ls_line TO lt_response.
        CLEAR ls_line.

      ENDLOOP.

      SORT lt_response BY plant material rangedate.

    ENDIF.

    lv_max_rows = lv_skip + lv_top.
    IF lv_skip > 0.
      lv_skip = lv_skip + 1.
    ENDIF.

    CLEAR lt_responseout.
    LOOP AT lt_response ASSIGNING FIELD-SYMBOL(<lfs_out_line_item>) FROM lv_skip TO lv_max_rows.
      ls_responseout = <lfs_out_line_item>.
      APPEND ls_responseout TO lt_responseout.
    ENDLOOP.

    io_response->set_total_number_of_records( lines( lt_response ) ).
    io_response->set_data( lt_responseout ).


  ENDMETHOD.
ENDCLASS.
