segment stack_segment

  stack_bottom = (stack_segment-main) shl 4

  db 4000h dup ?

  stack_top = stack_bottom + $
