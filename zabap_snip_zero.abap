*&---------------------------------------------------------------------*
*& Report  ZABAP_SNIP_ZERO
*&
*&---------------------------------------------------------------------*
*& Author: Ankit Kumar <mail2ankit85@gmail.com>
*& Description: Snippet to avoid printing zero values in smartforms
*&---------------------------------------------------------------------*

Report ZABAP_SNIP_ZERO.

DATA: num(13) TYPE p DECIMALS 2,
      char(16).

num = '256.44'.

WRITE num TO char NO-ZERO.
