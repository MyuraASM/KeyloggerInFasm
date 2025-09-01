format PE GUI
entry start

include 'win32a.inc'

section '.text' code readable executable

start:
    
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov [hStdOut], eax
    
    call write_start_msg
    call setup_winsock
    test eax, eax
    jnz error_exit

main_loop:
    
    call read_file
    test eax, eax
    jnz error_exit

    call connect_to_server
    test eax, eax
    jnz error_exit
    
    call send_http_request
    call receive_response
    
  
    invoke closesocket, [sockfd]

  
    invoke Sleep, 5000

    jmp main_loop  

setup_winsock:
    call write_winsock_msg
    invoke WSAStartup, 0x0202, wsadata
    test eax, eax
    jz .success
    mov eax, 1
    ret
.success:
    xor eax, eax
    ret

read_file:
  
    invoke CreateFileA, file_name, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je .error
    mov [file_handle], eax

  
    invoke GetFileSize, [file_handle], 0
    cmp eax, INVALID_FILE_SIZE
    je .close_error
    mov [file_size], eax

    
    cmp eax, 4096 - 256 
    ja .close_error

    
    invoke ReadFile, [file_handle], file_buffer, [file_size], bytes_read, 0
    test eax, eax
    jz .close_error
    mov eax, [bytes_read]
    mov [file_size], eax  

  
    invoke CloseHandle, [file_handle]

    
    call build_http_request

    xor eax, eax
    ret
.close_error:
    invoke CloseHandle, [file_handle]
.error:
    invoke WriteConsoleA, [hStdOut], msg_file_error, msg_file_error_len, bytes_written, 0
    mov eax, 1
    ret

build_http_request:
    
    mov edi, http_request
    mov ecx, 4096
    xor eax, eax
    rep stosb

    ;buld the headers
    mov edi, http_request
    mov esi, header_template
    call copy_string

    
    mov eax, [file_size]
    call append_number
    mov byte [edi], 13
    inc edi
    mov byte [edi], 10
    inc edi

    
    mov esi, header_end
    call copy_string
    mov esi, file_buffer
    mov ecx, [file_size]
    rep movsb

    
    mov byte [edi], 0

    
    mov eax, edi
    sub eax, http_request
    dec eax
    mov [http_request_len], eax

    ret

copy_string:
    
    cld
    mov al, [esi]
    test al, al
    jz .done
    stosb
    inc esi
    jmp copy_string
.done:
    ret

append_number:
    
    push ebx
    push ecx
    push edx
    mov ebx, 10
    xor ecx, ecx
    test eax, eax
    jnz .convert
    mov byte [edi], '0'
    inc edi
    jmp .done
.convert:
    test eax, eax
    jz .write
    xor edx, edx
    div ebx
    push edx
    inc ecx
    jmp .convert
.write:
    test ecx, ecx
    jz .done
    pop eax
    add al, '0'
    stosb
    dec ecx
    jmp .write
.done:
    pop edx
    pop ecx
    pop ebx
    ret

connect_to_server:
    call write_socket_msg
    invoke socket, AF_INET, SOCK_STREAM, 0
    cmp eax, INVALID_SOCKET
    je .error
    mov [sockfd], eax

    
    invoke gethostbyname, server_name
    test eax, eax
    jz .error
    mov eax, [eax + 12]  ;h_addr_list
    mov eax, [eax]       
    mov eax, [eax]       
    mov dword [servaddr + 4], eax  ;sin_addr

    
    mov word [servaddr + 0], AF_INET  
    invoke htons, 80                  
    mov word [servaddr + 2], ax       
    mov dword [servaddr + 8], 0      
    mov dword [servaddr + 12], 0

    call write_connect_msg
 invoke connect, [sockfd], servaddr, 16

    cmp eax, SOCKET_ERROR
    je .error
    
    xor eax, eax
    ret
.error:
    mov eax, 1
    ret

send_http_request:
    call write_send_msg
    invoke send, [sockfd], http_request, [http_request_len], 0
    cmp eax, SOCKET_ERROR
    je error_exit
    ret

receive_response:
    call write_receive_msg
    
.receive_loop:
    invoke recv, [sockfd], response_buffer, 4095, 0
    cmp eax, SOCKET_ERROR
    je .done
    cmp eax, 0
    je .done
    
  
    mov ebx, eax
    mov byte [response_buffer + ebx], 0
    
    
    invoke WriteConsoleA, [hStdOut], response_buffer, eax, bytes_written, 0
    
    jmp .receive_loop
    
.done:
    call write_done_msg
    ret

write_start_msg:
    invoke WriteConsoleA, [hStdOut], msg_start, msg_start_len, bytes_written, 0
    ret

write_winsock_msg:
    invoke WriteConsoleA, [hStdOut], msg_winsock, msg_winsock_len, bytes_written, 0
    ret

write_socket_msg:
    invoke WriteConsoleA, [hStdOut], msg_socket, msg_socket_len, bytes_written, 0
    ret

write_connect_msg:
    invoke WriteConsoleA, [hStdOut], msg_connect, msg_connect_len, bytes_written, 0
    ret

write_send_msg:
    invoke WriteConsoleA, [hStdOut], msg_send, msg_send_len, bytes_written, 0
    ret

write_receive_msg:
    invoke WriteConsoleA, [hStdOut], msg_receive, msg_receive_len, bytes_written, 0
    ret

write_done_msg:
    invoke WriteConsoleA, [hStdOut], msg_done, msg_done_len, bytes_written, 0
    ret

error_exit:
    invoke WriteConsoleA, [hStdOut], msg_error, msg_error_len, bytes_written, 0
    invoke WSAGetLastError
    invoke closesocket, [sockfd]
    invoke WSACleanup
    invoke Sleep, 5000
    invoke ExitProcess, 1

section '.data' data readable writeable

sockfd              dd INVALID_SOCKET
hStdOut             dd ?
bytes_written       dd ?
bytes_read          dd ?
file_handle         dd ?
file_size           dd ?

servaddr            rb 16    
wsadata             rb 408   
response_buffer     rb 4096  
file_buffer         rb 4096 
http_request        rb 4096  ; --- this is a buffer too
http_request_len    dd ?

file_name           db 'Readme.txt', 0
server_name         db 'lala.requestcatcher.com', 0


header_template:
db 'POST /test HTTP/1.1', 13, 10
db 'Host: lala.requestcatcher.com', 13, 10
db 'User-Agent: FASM-HTTP-Client/1.0', 13, 10
db 'Content-Type: application/x-www-form-urlencoded', 13, 10
db 'Content-Length: ', 0

header_end:
db 13, 10
db 'Connection: close', 13, 10
db 13, 10
db 0

msg_start          db 'Starting HTTP Client...', 13, 10, 0
msg_start_len      = $ - msg_start - 1
msg_winsock        db 'Initializing Winsock...', 13, 10, 0
msg_winsock_len    = $ - msg_winsock - 1
msg_socket         db 'Creating socket...', 13, 10, 0
msg_socket_len     = $ - msg_socket - 1
msg_connect        db 'Connecting to webseverr...', 13, 10, 0
msg_connect_len    = $ - msg_connect - 1
msg_send           db 'Sending HTTP request...', 13, 10, 0
msg_send_len       = $ - msg_send - 1
msg_receive        db 'Receiving response:', 13, 10, 0
msg_receive_len    = $ - msg_receive - 1
msg_done           db 13, 10, 'Connection closed.', 13, 10, 0
msg_done_len       = $ - msg_done - 1
msg_error          db 'ERROR!', 13, 10, 0
msg_error_len      = $ - msg_error - 1
msg_file_error     db 'ERROR reading  leee file!', 13, 10, 0
msg_file_error_len = $ - msg_file_error - 1

section '.idata' import data readable writeable

library kernel32, 'KERNEL32.DLL',\
        ws2_32, 'WS2_32.DLL'

import kernel32,\
       GetStdHandle, 'GetStdHandle',\
       WriteConsoleA, 'WriteConsoleA',\
       ExitProcess, 'ExitProcess',\
       Sleep, 'Sleep',\
       CreateFileA, 'CreateFileA',\
       ReadFile, 'ReadFile',\
       GetFileSize, 'GetFileSize',\
       CloseHandle, 'CloseHandle'

import ws2_32,\
       WSAStartup, 'WSAStartup',\
       WSACleanup, 'WSACleanup',\
       WSAGetLastError, 'WSAGetLastError',\
       socket, 'socket',\
       connect, 'connect',\
       recv, 'recv',\
       send, 'send',\
       closesocket, 'closesocket',\
       htons, 'htons',\
       gethostbyname, 'gethostbyname'


STD_OUTPUT_HANDLE  = -11
AF_INET            = 2
SOCK_STREAM        = 1
INVALID_SOCKET     = -1
SOCKET_ERROR       = -1
GENERIC_READ       = 0x80000000
OPEN_EXISTING      = 3
FILE_ATTRIBUTE_NORMAL = 0x80
INVALID_HANDLE_VALUE = -1
INVALID_FILE_SIZE  = -1
