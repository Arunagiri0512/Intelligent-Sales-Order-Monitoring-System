CLASS zcl_order_status DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
      INTERFACES if_oo_adt_classrun.
   METHODs  setorderstatus.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_order_status IMPLEMENTATION.
  METHOD setorderstatus.




  ENDMETHOD.



  METHOD if_oo_adt_classrun~main.
     data : lt_order TYPE TABLE OF zorder_status.

    lt_order = VALUE #( ( status_code = 'CREATED' status_text = 'Created' )
                         ( status_code = 'OPEN' status_text = 'Open' )
                         ( status_code = 'IN_TRASNIT' status_text = 'In transit' )
                         ( status_code = 'DELIVERED' status_text = 'Delivered' )
                         ( status_code = 'CANCELLED' status_text = 'Cancelled' )
                         ( status_code = 'RETURNED' status_text = 'Returned' ) ).

    modify zorder_status from table @lt_order.
    if sy-subrc = 0.
    commit WORK.
    endif.
  ENDMETHOD.

ENDCLASS.