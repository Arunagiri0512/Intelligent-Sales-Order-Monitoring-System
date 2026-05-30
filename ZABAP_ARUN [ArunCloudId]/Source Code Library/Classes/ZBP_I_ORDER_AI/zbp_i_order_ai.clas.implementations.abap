CLASS lhc_zi_item_ai DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS ValidatePrice FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZI_ITEM_AI~ValidatePrice.

ENDCLASS.

CLASS lhc_zi_item_ai IMPLEMENTATION.

  METHOD ValidatePrice.
        READ ENTITIES OF zi_order_ai IN LOCAL MODE
           ENTITY ZI_ITEM_AI
           ALL FIELDS
           WITH CORRESPONDING #( keys )
           RESULT DATA(lt_items).

      READ ENTITIES OF zi_order_ai IN LOCAL MODE
      ENTITY ZI_ITEM_AI BY \_Order
      ALL FIELDS
      WITH CORRESPONDING #( lt_items )
      RESULT DATA(lt_orders).

     LOOP AT lt_items INTO DATA(ls_item).
      READ TABLE lt_orders INTO DATA(ls_order) INDEX 1.
      if sy-subrc = 0.
        IF ls_item-NetPrice > ls_order-OrderAmount .
          APPEND VALUE #(
            %tky = ls_item-%tky
            ) TO failed-zi_item_ai.

          APPEND VALUE #(
            %tky = ls_item-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text     = 'Net Price cannot exceed Order Amount'
                        )  %element-NetPrice = if_abap_behv=>mk-on
                ) TO reported-zi_item_ai.
        ENDIF.
    endif.

  ENDLOOP.

  ENDMETHOD.

ENDCLASS.

*CLASS lhc_zai_invoice DEFINITION INHERITING FROM cl_abap_behavior_handler.
*
*  PRIVATE SECTION.
*
*    METHODS GenerateInvoice FOR MODIFY
*      IMPORTING keys FOR ACTION zai_invoice~GenerateInvoice RESULT result.
*
*ENDCLASS.
*
*CLASS lhc_zai_invoice IMPLEMENTATION.
*
*  METHOD GenerateInvoice.
*
*
*  ENDMETHOD.
*ENDCLASS.

CLASS lhc_zi_order_ai DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS GenerateAIAnalysis FOR MODIFY
      IMPORTING keys FOR ACTION zi_order_ai~GenerateAIAnalysis .
    METHODS SetDefaultValues FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zi_order_ai~SetDefaultValues.
    METHODS GenerateInvoice FOR MODIFY
      IMPORTING keys FOR ACTION zi_order_ai~GenerateInvoice .

ENDCLASS.

CLASS lhc_zi_order_ai IMPLEMENTATION.

*  METHOD GenerateAIAnalysis.
*    DATA:
*    lo_ai_service TYPE REF TO zcl_ai_service,
*    ls_ai_result  TYPE zcl_ai_service=>ty_ai_response.
*
*    DATA ls_recomm TYPE zai_recommd.
*
*  CREATE OBJECT lo_ai_service.
*
*    READ ENTITies of zi_order_ai in LOCAL MODE ENTITY zi_order_ai
*    ALL FIELDS
*    WITH CORRESPONDING #( keys )
*    RESULT DATA(lt_orders).
*     LOOP AT lt_orders INTO DATA(ls_order).
*
*        "====================================================
*    " CALL AI SERVICE
*    "====================================================
*    TRY.
*        ls_ai_result = lo_ai_service->analyze_order_comment(
*            iv_comment = ls_order-OrderComments
*          ).
*      CATCH cx_http_dest_provider_error cx_web_http_client_error.
*        "handle exception
*    ENDTRY.
*
*    "====================================================
*    " UPDATE HEADER
*    "====================================================
*    MODIFY ENTITY IN LOCAL MODE zi_order_ai
*      UPDATE FIELDS (
*        AIPriority
*        AISentiment
*        AISummary
*      )
*      WITH VALUE #(
*
*        (
*          %tky        = ls_order-%tky
*          AIPriority  = ls_ai_result-priority
*          AISentiment = ls_ai_result-sentiment
*          AISummary   = ls_ai_result-summary
*        )
*
*      ).
*
*    "====================================================
*    " INSERT RECOMMENDATION
*    "====================================================
*    CLEAR ls_recomm.
*
*    ls_recomm-client = sy-mandt.
*
*    TRY.
*        ls_recomm-recommendation_id =   cl_system_uuid=>create_uuid_x16_static( ).
*      CATCH cx_uuid_error.
*        "handle exception
*    ENDTRY.
*
*    ls_recomm-order_id = ls_order-OrderId.
*
*    ls_recomm-kunnr = ls_order-CustomerName.
*
*    ls_recomm-action_type = 'FOLLOWUP'.
*
*    ls_recomm-priority = ls_ai_result-priority.
*
*    ls_recomm-recommendation_text = ls_ai_result-summary.
*
*    ls_recomm-ai_reason = ls_ai_result-full_text.
*
*    ls_recomm-status = 'Analyzed'.
*
*    ls_recomm-assigned_to = sy-uname.
*
*    ls_recomm-due_date = sy-datum + 7.
*
*    ls_recomm-created_by = sy-uname.
*
*    GET TIME STAMP FIELD ls_recomm-created_at.
*
**    modify zai_recommd FROM @ls_recomm.
*    MODIFY ENTITIES OF zi_order_ai
*    IN LOCAL MODE ENTITY zi_order_ai CREATE BY \_Recommd
*    FIELDS (
*    RecommendationId
*    OrderId
*    Kunnr
*    ActionType
*    Priority
*    RecommendationText
*    AiReason
*    Status
*    AssignedTo
*    DueDate
*    CreatedBy
*    CreatedAt
*  )
*
*  WITH VALUE #(
*    (
*      %tky = ls_order-%tky
*      %target = VALUE #( (
*        RecommendationId   = ls_recomm-recommendation_id
*        OrderId            = ls_order-OrderId
*        Kunnr              = ls_order-CustomerName
*        ActionType         = 'FOLLOWUP'
*        Priority           = ls_ai_result-priority
*        RecommendationText = ls_ai_result-summary
*        AiReason           = ls_ai_result-full_text
*        Status             = 'Analyzed'
*        AssignedTo         = sy-uname
*        DueDate            = sy-datum + 7
*        CreatedBy          = sy-uname
*        CreatedAt          = ls_recomm-created_at
*
*      ) )
*    )
*  ).
*
*
*     ENDLOOP.
*     READ ENTITIES OF zi_order_ai IN LOCAL MODE ENTITY zi_order_ai
*      ALL FIELDS
*      WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_result).
*        result = VALUE #(
*          FOR ls_result IN lt_result
*          (
*            %tky   = ls_result-%tky
*            %param = ls_result
*          )
*        ).
*  ENDMETHOD.


  METHOD GenerateAIAnalysis.

    DATA:
      lo_ai_service TYPE REF TO zcl_ai_service,
      ls_ai_result  TYPE zcl_ai_service=>ty_ai_response.

    DATA:
      lv_uuid TYPE sysuuid_x16.

    CREATE OBJECT lo_ai_service.

    "====================================================
    " READ CURRENT SALES ORDERS
    "====================================================

    READ ENTITIES OF zi_order_ai
      IN LOCAL MODE
      ENTITY zi_order_ai
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    LOOP AT lt_orders INTO DATA(ls_order).

      "====================================================
      " CALL AI SERVICE
      "====================================================

      CLEAR ls_ai_result.

      TRY.

          ls_ai_result = lo_ai_service->analyze_order_comment(
            iv_comment = ls_order-OrderComments
          ).

        CATCH cx_http_dest_provider_error
              cx_web_http_client_error
              cx_uuid_error.

          APPEND VALUE #(
            %msg = new_message_with_text(
                      severity = if_abap_behv_message=>severity-error
                      text     = 'AI service call failed'
                   )
          ) TO reported-zi_order_ai.

          RETURN.

      ENDTRY.


      "====================================================
      " UPDATE SALES ORDER HEADER
      "====================================================

      MODIFY ENTITIES OF zi_order_ai
        IN LOCAL MODE

        ENTITY zi_order_ai

        UPDATE FIELDS (
          AiPriority
          AiSentiment
          AiSummary
        )

        WITH VALUE #(

          (

            %tky        = ls_order-%tky
            AiPriority  = ls_ai_result-priority
            AiSentiment = ls_ai_result-sentiment
            AiSummary   = ls_ai_result-summary

          )

        ).


      "====================================================
      " GENERATE UUID
      "====================================================

      TRY.

          lv_uuid = cl_system_uuid=>create_uuid_x16_static( ).

        CATCH cx_uuid_error.

          APPEND VALUE #(
            %msg = new_message_with_text(
                      severity = if_abap_behv_message=>severity-error
                      text     = 'UUID generation failed'
                   )
          ) TO reported-zi_order_ai.

          RETURN.

      ENDTRY.


      "====================================================
      " CREATE AI RECOMMENDATION
      "====================================================

      MODIFY ENTITIES OF zi_order_ai
        IN LOCAL MODE

        ENTITY zi_order_ai

        CREATE BY \_Recommd

         AUTO FILL CID

        FIELDS (
          RecommendationId
          OrderId
          Kunnr
          ActionType
          Priority
          RecommendationText
          AiReason
          Status
          AssignedTo
          DueDate
          CreatedBy
          CreatedAt
        )

        WITH VALUE #(

          (
            %tky = ls_order-%tky
            %target = VALUE #( (
              RecommendationId   = lv_uuid
              Kunnr              = ls_order-CustomerName
              OrderId            = ls_order-OrderId
              ActionType         = 'FOLLOWUP'
              Priority           = ls_ai_result-priority
              RecommendationText = ls_ai_result-summary
              AiReason           = ls_ai_result-full_text
              Status             = 'ANALYZED'
              AssignedTo         = sy-uname
              DueDate            = sy-datum + 7
              CreatedBy          = sy-uname
              CreatedAt          = cl_abap_context_info=>get_system_time( )
            ) )
          )
        ).

    ENDLOOP.
    "====================================================
    " SUCCESS MESSAGE
    "====================================================

    APPEND VALUE #(

      %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-success
                text     = 'AI Analysis completed successfully' )
                ) TO reported-zi_order_ai.
  ENDMETHOD.


  METHOD SetDefaultValues.

    MODIFY ENTITIES OF zi_order_ai
      IN LOCAL MODE
      ENTITY zi_order_ai
      UPDATE FIELDS ( Currcode Status )
      WITH VALUE #(   FOR key IN keys
        (
          %tky      = key-%tky
          Currcode  = 'EUR'
          Status    = 'Created'
        )
      ).

    READ ENTITIES OF zi_order_ai
        IN LOCAL MODE ENTITY zi_order_ai by \_Items
         ALL FIELDS WITH CORRESPONDING #( keys ) RESULT data(lt_item).
   MODIFY ENTITIES OF zi_order_ai
  IN LOCAL MODE ENTITY zi_item_ai
         UPDATE FIELDS ( Currcode UnitField )
             WITH VALUE #(
                FOR ls_item IN lt_item
                (
                  %tky      = ls_item-%tky
                  Currcode  = 'EUR'
                  UnitField = 'CM'
                )
              ).
  ENDMETHOD.


  METHOD generateinvoice.
    READ ENTITIES OF zi_order_ai  IN LOCAL MODE
      ENTITY zi_order_ai  ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_order).
    LOOP AT lt_order INTO DATA(ls_order).
      MODIFY ENTITIES OF zi_order_ai
            IN LOCAL MODE
            ENTITY zi_order_ai
            CREATE BY \_invoice  AUTO FILL CID
             FIELDS ( InvoiceNo OrderId CreatedDate Currcode InvoiceType NetValue CustomerName  )
             WITH VALUE #(
                   ( %tky = ls_order-%tky
                     %target = VALUE #( (
                           InvoiceNo = 'INV003912'
                           OrderId   = ls_order-OrderId
                           CreatedDate = sy-datum
                           Currcode  =  'EUR'
                           InvoiceType = 'UF'
                           NetValue = ls_order-OrderAmount
                           CustomerName = ls_order-CustomerName ) ) ) ).
     ENDLOOP.

        MODIFY ENTITIES OF zi_order_ai
                IN LOCAL MODE
                ENTITY zi_order_ai
                UPDATE FIELDS (
                  Status
                )
                WITH VALUE #(
                  (
                    %tky        = ls_order-%tky
                    Status      = 'Invoiced' ) ).

     READ ENTITIES OF zi_order_ai
        in local mode ENTITY zi_order_ai by \_Items
        ALL FIELDS WITH CORRESPONDING #( lt_order )
        result data(lt_items).

     MODIFY ENTITIES OF zi_order_ai
      in LOCAL MODE ENTITY zi_item_ai
        UPDATE fields
                    ( ItemStatus )
                with VALUE #(   fOR ls_item IN lt_items
    (
      %tky = ls_item-%tky
      ItemStatus = 'Invoiced'
    ) ) .

     APPEND VALUE #(
      %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-success
                text     = 'Invoice Generated Successfully'  ) ) TO reported-zi_order_ai.
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
