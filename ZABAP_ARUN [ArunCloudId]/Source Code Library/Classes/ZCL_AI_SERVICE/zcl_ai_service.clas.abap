CLASS zcl_ai_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  TYPES:
      BEGIN OF ty_ai_response,
        priority   TYPE string,
        sentiment  TYPE string,
        summary    TYPE string,
        full_text  TYPE string,
      END OF ty_ai_response.

    METHODS analyze_order_comment
      IMPORTING
        iv_comment TYPE string
      RETURNING
        VALUE(rs_response) TYPE ty_ai_response
      RAISING
        cx_http_dest_provider_error
        cx_web_http_client_error.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ai_service IMPLEMENTATION.
  METHOD analyze_order_comment.
     DATA:
      lv_url      TYPE string,
      lv_request  TYPE string,
      lv_response TYPE string.
    TYPES: BEGIN OF ty_content,
         type TYPE string,
         text TYPE string,
       END OF ty_content.

    TYPES: ty_t_content TYPE STANDARD TABLE OF ty_content
           WITH EMPTY KEY.

    TYPES: BEGIN OF ty_claude_response,
             content TYPE ty_t_content,
           END OF ty_claude_response.

    DATA: ls_claude_response TYPE ty_claude_response.
    DATA:
      lo_dest        TYPE REF TO if_http_destination,
      lo_http_client TYPE REF TO if_web_http_client,
      lo_request     TYPE REF TO if_web_http_request,
      lo_response    TYPE REF TO if_web_http_response.

TYPES: BEGIN OF ty_ai_response,
         priority  TYPE string,
         sentiment TYPE string,
         summary   TYPE string,
         recommendation type string,
       END OF ty_ai_response.

DATA: ls_ai_response TYPE ty_ai_response.
    DATA : lv_message TYPE string.

    lv_url = 'https://api.anthropic.com/v1/messages'.

    lo_dest =  cl_http_destination_provider=>create_by_url( lv_url ).

    lo_http_client =
      cl_web_http_client_manager=>create_by_http_destination(  i_destination = lo_dest  ).


    lo_request = lo_http_client->get_http_request( ).


    lo_request->set_header_field(
      i_name  = 'Content-Type'
      i_value = 'application/json'
    ).
    lo_request->set_header_field(
      EXPORTING
        i_name  = 'anthropic-version'
        i_value = '2023-06-01'
*      RECEIVING
*        r_value =
    ).
*    CATCH cx_web_message_error.

    lo_request->set_header_field(
      EXPORTING
        i_name  = 'x-api-key'
        i_value = 'YOUR-API-KEY'
    ).
*    CATCH cx_web_message_error.
    CONCATENATE
        '{'
        '"model":"claude-haiku-4-5-20251001",'
        '"max_tokens":300,'
        '"messages":['
        '{'
        '"role":"user",'
        '"content":"Analyze this order comment and return ONLY valid JSON in below format: '
        '{'
        '\"priority\":\"\",'
        '\"sentiment\":\"\",'
        '\"summary\":\"\",'
        '\"recommemdation\":\"\"'
        '}'
        ' Order Comment: ' iv_comment
        '"'
        '}'
        ']'
        '}'

        INTO lv_request
        RESPECTING BLANKS.

    lo_request->set_text( lv_request ).

    lo_response =
      lo_http_client->execute(
        if_web_http_client=>post
      ).

    lv_response = lo_response->get_text( ).
    REPLACE ALL OCCURRENCES OF '```json' IN lv_response WITH ''.
    REPLACE ALL OCCURRENCES OF '```'     IN lv_response WITH ''.
    /ui2/cl_json=>deserialize(
      EXPORTING
        json = lv_response
      CHANGING
        data = ls_claude_response
    ).
    READ TABLE ls_claude_response-content INTO DATA(ls_content) INDEX 1.
    REPLACE ALL OCCURRENCES OF '```json'  IN ls_content-text WITH ''.
    REPLACE ALL OCCURRENCES OF '```'  IN ls_content-text WITH ''.
    /ui2/cl_json=>deserialize(
          EXPORTING
            json = ls_content-text
          CHANGING
            data = ls_ai_response
        ).
*    FIND FIRST OCCURRENCE OF REGEX '"message":\s*"([^"]*)"' IN lv_response SUBMATCHES lv_message.

    rs_response-priority  =  ls_ai_response-priority.
    rs_response-sentiment = ls_ai_response-sentiment.
    rs_response-summary   = ls_ai_response-recommemdation.
    rs_response-full_text = ls_ai_response-summary.

*    IF lv_response CS 'Positive'.
*
*      rs_response-priority  = 'LOW'.
*      rs_response-sentiment = 'Positive'.
*      rs_response-summary   = 'Customer feedback positive'.
*
*    ENDIF.

  ENDMETHOD.

ENDCLASS.