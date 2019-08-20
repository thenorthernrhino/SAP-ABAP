*&---------------------------------------------------------------------*
*& Report  ZABAP_SNIP_SIGN_SHIFT
*&
*&---------------------------------------------------------------------*
*& Author: Ankit Kumar <mail2ankit85@gmail.com>
*& Description: Snippet to shift negative sign from right to left in type QAUN field
*& (for eg. 12345- to -12345)
*&---------------------------------------------------------------------*
Report  ZABAP_SNIP_SIGN_SHIFT.

DATA: p_amount TYPE NETWR.

IF p_amount LT 0.

  SHIFT p_amount RIGHT DELETING TRAILING '-'.
  SHIFT p_amount LEFT DELETING LEADING ' '.
  CONCATENATE '-' p_amount INTO p_amount.

ELSE.

  SHIFT p_amount LEFT DELETING LEADING ' '.

ENDIF.
