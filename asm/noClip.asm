[ENABLE]
// allocate memory
alloc(newmemPhase, 2048)
alloc(newmemStay, 2048)

// ================================================
// Hook 1: Phase Through Objects
// ================================================

label(returnherePhase)
label(doAdd)
label(doSub)
label(doAscend)
label(doDescend)
label(restore)

newmemPhase:
  push edi
  push ebx

// resolve pointer to local player base address
  mov edi, ["Cube.exe"+36B1C8]
  test edi, edi
  je doSub
  mov edi, [edi+39C]
  test edi, edi
  je doSub

// apply x-coord offset to local player base address
  mov ebx, edi
  add ebx, 10
  cmp ecx, ebx
  je doAdd

// apply y-coord offset to local player base address
  mov ebx, edi
  add ebx, 18
  cmp ecx, ebx
  je doAdd

// apply z-coord offset to local player base address
  mov ebx, edi
  add ebx, 20
  cmp ecx, ebx
  je doAscend

// execute original code if register is not local player x or y
doSub:
  sub [ecx], eax
  jmp restore

// execute custom code if register is local player x or y
doAdd:
  add [ecx], eax
  jmp restore

// execute custom code if register is local player z and spacebar = true
doAscend:
  mov edi, ["DINPUT8.dll"+312F1] // static spacebar input address
  test edi, edi // if 0 then spacebar is not pressed
  je doDescend
  // actual ascend logic now
  add [ecx], eax // regular add for now, requires adjustments for quicker ascension
  jmp restore

// execute custom code if register is local player z and shift = true + spacebar = false
doDescend:
  mov edi, ["DINPUT8.dll"+312E2] // static shift input address
  test edi, edi // if 0 then shift is not pressed
  je doSub // don't write any custom code for z if neither spacebar nor shift are pressed
  // actual descend logic now
  add [ecx], eax // regular add for now, requires adjustments for quicker descend
  jmp restore

// restore modified registers and run rest of original code + exit
restore:
  pop ebx
  pop edi
  mov eax, [edx+04]
  jmp returnherePhase

// install first hook
"Cube.exe"+2CA08:
  jmp newmemPhase
returnherePhase:

// ================================================
// Hook 2: Stay Inside Objects
// ================================================

label(returnhereStay)

newmemStay:
  // remove mov [edx+20], esi
  mov [edx+24],edi
  jmp returnhereStay

// install second hook
"Cube.exe"+20B9D8:
  jmp newmemStay
  nop
returnhereStay:

[DISABLE]

// clean up hooks
dealloc(newmemPhase)
dealloc(newmemStay)

// restore original code for first hook
"Cube.exe"+2CA08:
  db 29 01 8B 42 04
//sub [ecx],eax
//mov eax,[edx+04]

// restore original code for second hook
"Cube.exe"+20B9D8:
  db 89 72 20 89 7A 24
//mov [edx+20],esi
//mov [edx+24],edi
