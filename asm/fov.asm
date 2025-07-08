[ENABLE]
// allocate memory
alloc(newmemZoomOUT,2048)
alloc(newmemZoomIN,2048)

// ================================================
// Hook 1: Remove Zoom OUT limiter
// ================================================

label(returnhereZoomOUT)

newmemZoomOUT:
  jmp returnhereZoomOUT // nop

// install first hook
"Cube.exe"+7EFE9:
  jmp newmemZoomOUT
  nop 5
returnhereZoomOUT:

// ================================================
// Hook 2: Remove Zoom IN limiter
// ================================================

label(returnhereZoomIN)

newmemZoomIN:
  jmp returnhereZoomIN // nop

// install second hook
"Cube.exe"+7EFCE:
  jmp newmemZoomIN
  nop 5
returnhereZoomIN:

[DISABLE]

// clean up hooks
dealloc(newmemZoomOUT)
dealloc(newmemZoomIN)

// restore original first hook
"Cube.exe"+7EFE9:
  db C7 81 C0 01 00 00 00 00 60 41
//mov [ecx+000001C0],41600000

// restore original second hook
dealloc(newmem)
"Cube.exe"+7EFCE:
  db C7 81 C0 01 00 00 00 00 00 00
//mov [ecx+000001C0],00000000
